<?php

declare(strict_types=1);

final class QueueService
{
    public function __construct(private readonly QueueRepository $repository)
    {
    }

    public function joinQueue(array $payload): array
    {
        $studentName = trim((string) ($payload['student_name'] ?? ''));
        $transactionType = trim((string) ($payload['transaction_type'] ?? ''));
        $qrToken = $this->normalizeQrToken((string) ($payload['qr_token'] ?? ''));
        $entryMode = strtoupper(trim((string) ($payload['entry_mode'] ?? 'QR')));

        if ($studentName === '' || $transactionType === '') {
            throw new InvalidArgumentException('student_name and transaction_type are required.');
        }

        if ($entryMode !== 'MANUAL' && !$this->isValidQrToken($qrToken)) {
            throw new InvalidArgumentException('Invalid or expired QR token.');
        }

        $queueNumber = $this->repository->nextQueueNumber();
        $this->repository->createQueue(
            $queueNumber,
            $studentName,
            $transactionType,
            'WAITING',
        );
        $this->repository->logAction(
            sprintf('Queue joined: %s via %s', $queueNumber, $entryMode),
        );

        return [
            'success' => true,
            'message' => 'Queue joined successfully.',
            'queue_number' => $queueNumber,
            'status' => 'WAITING',
            'entry_mode' => $entryMode,
        ];
    }

    public function getQueueNumber(string $studentName): array
    {
        $queue = $this->repository->findLatestByStudent($studentName);

        if ($queue === null) {
            throw new RuntimeException('Queue number not found for the given student.');
        }

        return [
            'success' => true,
            'queue_number' => $queue['queue_number'],
            'status' => $queue['status'],
        ];
    }

    public function submitForm(array $payload): array
    {
        $payload['entry_mode'] = 'MANUAL';

        return $this->joinQueue($payload);
    }

    public function getQueueStatus(?string $queueNumber, ?string $studentName): array
    {
        $queue = $queueNumber !== null && $queueNumber !== ''
            ? $this->repository->findByQueueNumber($queueNumber)
            : $this->repository->findLatestByStudent((string) $studentName);

        if ($queue === null) {
            throw new RuntimeException('Queue entry not found.');
        }

        $board = $this->getCurrentQueue();
        $peopleAhead = $this->peopleAhead($queue['queue_number'], $board['now_serving']);

        return [
            'success' => true,
            'queue_number' => $queue['queue_number'],
            'now_serving' => $board['now_serving'],
            'people_ahead' => $peopleAhead,
            'estimated_wait_minutes' => $peopleAhead * 3,
            'status' => $queue['status'],
            'transaction_type' => $queue['transaction_type'],
        ];
    }

    public function getCurrentQueue(): array
    {
        $currentCalledQueue = $this->repository->getCurrentCalledQueue();
        $latestServedQueue = $this->repository->getLatestServedQueue();
        $fallbackQueue = $currentCalledQueue ?? $latestServedQueue;

        return [
            'success' => true,
            'now_serving' => $fallbackQueue['queue_number'] ?? 'A000',
            'next_queues' => array_map(
                static fn (array $queue): string => $queue['queue_number'],
                $this->repository->getNextQueues(3),
            ),
            'queues' => $this->repository->getQueueSnapshot(),
            'updated_at' => (new DateTimeImmutable())->format(DATE_ATOM),
        ];
    }

    public function nextQueue(string $processedBy): array
    {
        $currentCalledQueue = $this->repository->getCurrentCalledQueue();
        if ($currentCalledQueue !== null) {
            $this->repository->updateStatus((int) $currentCalledQueue['id'], 'DONE');
            $this->repository->insertTransaction(
                $currentCalledQueue['queue_number'],
                $processedBy,
            );
        }

        $nextWaitingQueue = $this->repository->getNextWaitingQueue();
        if ($nextWaitingQueue !== null) {
            $this->repository->updateStatus((int) $nextWaitingQueue['id'], 'CALLED');
            $this->repository->logAction(
                sprintf('Queue called: %s', $nextWaitingQueue['queue_number']),
            );
        }

        return $this->getCurrentQueue();
    }

    public function skipQueue(): array
    {
        $currentCalledQueue = $this->repository->getCurrentCalledQueue();
        if ($currentCalledQueue === null) {
            throw new RuntimeException('No active queue to skip.');
        }

        $this->repository->updateStatus((int) $currentCalledQueue['id'], 'SKIPPED');
        $this->repository->logAction(
            sprintf('Queue skipped: %s', $currentCalledQueue['queue_number']),
        );

        $nextWaitingQueue = $this->repository->getNextWaitingQueue();
        if ($nextWaitingQueue !== null) {
            $this->repository->updateStatus((int) $nextWaitingQueue['id'], 'CALLED');
            $this->repository->logAction(
                sprintf('Queue called after skip: %s', $nextWaitingQueue['queue_number']),
            );
        }

        return $this->getCurrentQueue();
    }

    public function continueQueue(?string $queueNumber): array
    {
        $skippedQueue = $this->repository->getSkippedQueue($queueNumber);
        if ($skippedQueue === null) {
            throw new RuntimeException('Skipped queue not found.');
        }

        $this->repository->rescheduleSkippedQueue((int) $skippedQueue['id']);
        $this->repository->logAction(
            sprintf('Skipped queue resumed: %s', $skippedQueue['queue_number']),
        );

        $board = $this->getCurrentQueue();
        $board['message'] = 'Skipped queue moved to the next waiting position.';

        return $board;
    }

    public function buildNotificationBatch(int $threshold = 5): array
    {
        $currentCalledQueue = $this->repository->getCurrentCalledQueue();
        $currentSequence = $this->queueSequence($currentCalledQueue['queue_number'] ?? '');

        if ($currentSequence === 0) {
            return [
                'success' => true,
                'notifications' => [],
                'message' => 'No active queue is currently being called.',
            ];
        }

        $notifications = [];
        foreach ($this->repository->getWaitingQueues() as $queue) {
            $distance = $this->queueSequence($queue['queue_number']) - $currentSequence;
            if ($distance > 0 && $distance <= $threshold) {
                $this->repository->recordNotification($queue['queue_number']);
                $notifications[] = [
                    'queue_number' => $queue['queue_number'],
                    'topic' => 'queue_' . $queue['queue_number'],
                    'title' => 'ExeQueue Alert',
                    'body' => sprintf(
                        'Your queue number %s is approaching. Please prepare to proceed to the cashier.',
                        $queue['queue_number'],
                    ),
                    'distance' => $distance,
                ];
            }
        }

        return [
            'success' => true,
            'notifications' => $notifications,
            'message' => 'Notification payloads prepared for Firebase Cloud Messaging.',
        ];
    }

    private function peopleAhead(string $queueNumber, string $nowServing): int
    {
        $targetSequence = $this->queueSequence($queueNumber);
        $currentSequence = $this->queueSequence($nowServing);

        if ($targetSequence === 0 || $currentSequence === 0) {
            return 0;
        }

        return max($targetSequence - $currentSequence, 0);
    }

    private function isValidQrToken(string $token): bool
    {
        if ($token === '') {
            return false;
        }

        return str_starts_with(strtoupper($token), 'JOIN-');
    }

    private function normalizeQrToken(string $payload): string
    {
        $payload = trim($payload);
        if ($payload === '') {
            return '';
        }

        if (str_starts_with(strtoupper($payload), 'JOIN-')) {
            return $payload;
        }

        $parts = parse_url($payload);
        if (!is_array($parts)) {
            return $payload;
        }

        $query = [];
        parse_str((string) ($parts['query'] ?? ''), $query);

        foreach (['qr_token', 'token'] as $key) {
            $candidate = $query[$key] ?? null;
            if (!is_string($candidate)) {
                continue;
            }

            $candidate = trim($candidate);
            if ($candidate !== '' && str_starts_with(strtoupper($candidate), 'JOIN-')) {
                return $candidate;
            }
        }

        return $payload;
    }

    private function queueSequence(string $queueNumber): int
    {
        if (preg_match('/(\d+)/', $queueNumber, $matches) !== 1) {
            return 0;
        }

        return (int) $matches[1];
    }
}

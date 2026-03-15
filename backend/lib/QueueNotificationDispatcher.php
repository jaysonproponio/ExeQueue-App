<?php

declare(strict_types=1);

final class QueueNotificationDispatcher
{
    public function __construct(
        private readonly QueueService $queueService,
        private readonly QueueRepository $queueRepository,
        private readonly ?FirebaseMessagingClient $firebaseMessagingClient,
    ) {
    }

    public function dispatchThresholdNotifications(int $threshold = 5): array
    {
        $batch = $this->queueService->buildNotificationBatch($threshold);
        $notifications = $batch['notifications'] ?? [];
        if (!is_array($notifications) || $notifications === []) {
            return [
                'success' => true,
                'sent' => [],
                'skipped' => [],
                'failed' => [],
                'message' => (string) ($batch['message'] ?? 'There are no threshold notifications to send.'),
            ];
        }

        if ($this->firebaseMessagingClient === null) {
            return [
                'success' => false,
                'sent' => [],
                'skipped' => [],
                'failed' => array_map(
                    static fn (array $notification): array => [
                        'queue_number' => (string) ($notification['queue_number'] ?? ''),
                        'error' => 'Firebase Cloud Messaging is not configured.',
                    ],
                    $notifications,
                ),
                'message' => 'Firebase Cloud Messaging is not configured.',
            ];
        }

        $sent = [];
        $skipped = [];
        $failed = [];
        foreach ($notifications as $notification) {
            $queueNumber = trim((string) ($notification['queue_number'] ?? ''));
            if ($queueNumber === '') {
                continue;
            }

            if ($this->queueRepository->hasNotificationRecord($queueNumber)) {
                $skipped[] = [
                    'queue_number' => $queueNumber,
                    'reason' => 'already_sent',
                ];
                continue;
            }

            try {
                $messageId = $this->firebaseMessagingClient->sendQueueAlert($notification);
                $this->queueRepository->recordNotification($queueNumber);
                $sent[] = [
                    'queue_number' => $queueNumber,
                    'message_id' => $messageId,
                ];
            } catch (Throwable $exception) {
                $failed[] = [
                    'queue_number' => $queueNumber,
                    'error' => $exception->getMessage(),
                ];
            }
        }

        return [
            'success' => $failed === [],
            'sent' => $sent,
            'skipped' => $skipped,
            'failed' => $failed,
            'message' => $this->buildSummaryMessage($sent, $skipped, $failed),
        ];
    }

    private function buildSummaryMessage(array $sent, array $skipped, array $failed): string
    {
        return sprintf(
            'Notifications sent: %d, skipped: %d, failed: %d.',
            count($sent),
            count($skipped),
            count($failed),
        );
    }
}

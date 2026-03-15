<?php

declare(strict_types=1);

final class QueueRepository
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    public function nextQueueNumber(string $prefix = 'A'): string
    {
        $statement = $this->pdo->query(
            'SELECT queue_number FROM queues ORDER BY id DESC LIMIT 1',
        );
        $lastQueueNumber = $statement->fetchColumn();

        if (is_string($lastQueueNumber) && preg_match('/^([A-Z]+)(\d+)$/', $lastQueueNumber, $matches) === 1) {
            $prefix = $matches[1];
            $sequence = (int) $matches[2] + 1;
        } else {
            $sequence = 1;
        }

        return sprintf('%s%03d', $prefix, $sequence);
    }

    public function createQueue(
        string $queueNumber,
        string $studentName,
        ?string $studentId,
        string $transactionType,
        string $status,
    ): array {
        $statement = $this->pdo->prepare(
            'INSERT INTO queues (queue_number, student_name, student_id, transaction_type, status, created_at)
             VALUES (:queue_number, :student_name, :student_id, :transaction_type, :status, NOW())',
        );
        $statement->execute(
            [
                ':queue_number' => $queueNumber,
                ':student_name' => $studentName,
                ':student_id' => $studentId,
                ':transaction_type' => $transactionType,
                ':status' => $status,
            ],
        );

        return $this->findByQueueNumber($queueNumber) ?? [];
    }

    public function findByQueueNumber(string $queueNumber): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT * FROM queues WHERE queue_number = :queue_number LIMIT 1',
        );
        $statement->execute([':queue_number' => $queueNumber]);
        $queue = $statement->fetch();

        return is_array($queue) ? $queue : null;
    }

    public function findLatestByStudent(string $studentName): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT * FROM queues WHERE student_name = :student_name ORDER BY id DESC LIMIT 1',
        );
        $statement->execute([':student_name' => $studentName]);
        $queue = $statement->fetch();

        return is_array($queue) ? $queue : null;
    }

    public function getCurrentCalledQueue(): ?array
    {
        $statement = $this->pdo->query(
            "SELECT * FROM queues WHERE status = 'CALLED' ORDER BY created_at ASC, id ASC LIMIT 1",
        );
        $queue = $statement->fetch();

        return is_array($queue) ? $queue : null;
    }

    public function getLatestServedQueue(): ?array
    {
        $statement = $this->pdo->query(
            "SELECT * FROM queues WHERE status IN ('CALLED', 'DONE') ORDER BY id DESC LIMIT 1",
        );
        $queue = $statement->fetch();

        return is_array($queue) ? $queue : null;
    }

    public function getNextWaitingQueue(): ?array
    {
        $statement = $this->pdo->query(
            "SELECT * FROM queues WHERE status = 'WAITING' ORDER BY created_at ASC, id ASC LIMIT 1",
        );
        $queue = $statement->fetch();

        return is_array($queue) ? $queue : null;
    }

    public function getNextQueues(int $limit = 3): array
    {
        $statement = $this->pdo->prepare(
            "SELECT * FROM queues WHERE status = 'WAITING' ORDER BY created_at ASC, id ASC LIMIT :limit",
        );
        $statement->bindValue(':limit', $limit, PDO::PARAM_INT);
        $statement->execute();

        return $statement->fetchAll() ?: [];
    }

    public function getWaitingQueues(): array
    {
        $statement = $this->pdo->query(
            "SELECT * FROM queues WHERE status = 'WAITING' ORDER BY created_at ASC, id ASC",
        );

        return $statement->fetchAll() ?: [];
    }

    public function getSkippedQueue(?string $queueNumber = null): ?array
    {
        if ($queueNumber !== null && $queueNumber !== '') {
            $statement = $this->pdo->prepare(
                "SELECT * FROM queues WHERE queue_number = :queue_number AND status = 'SKIPPED' LIMIT 1",
            );
            $statement->execute([':queue_number' => $queueNumber]);
        } else {
            $statement = $this->pdo->query(
                "SELECT * FROM queues WHERE status = 'SKIPPED' ORDER BY created_at ASC, id ASC LIMIT 1",
            );
        }

        $queue = $statement->fetch();

        return is_array($queue) ? $queue : null;
    }

    public function updateStatus(int $id, string $status): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE queues SET status = :status WHERE id = :id',
        );
        $statement->execute(
            [
                ':status' => $status,
                ':id' => $id,
            ],
        );
    }

    public function rescheduleSkippedQueue(int $id): void
    {
        $statement = $this->pdo->prepare(
            "UPDATE queues SET status = 'WAITING', created_at = NOW() WHERE id = :id",
        );
        $statement->execute([':id' => $id]);
    }

    public function getQueueSnapshot(): array
    {
        $statement = $this->pdo->query(
            "SELECT queue_number, student_name, student_id, transaction_type, status, created_at
             FROM queues
             ORDER BY FIELD(status, 'CALLED', 'WAITING', 'SKIPPED', 'DONE'), created_at ASC, id ASC",
        );

        return $statement->fetchAll() ?: [];
    }

    public function insertTransaction(string $queueNumber, string $processedBy): void
    {
        $statement = $this->pdo->prepare(
            'INSERT INTO transactions (queue_number, processed_by, completed_at)
             VALUES (:queue_number, :processed_by, NOW())',
        );
        $statement->execute(
            [
                ':queue_number' => $queueNumber,
                ':processed_by' => $processedBy,
            ],
        );
    }

    public function recordNotification(string $queueNumber): void
    {
        $statement = $this->pdo->prepare(
            'INSERT INTO notifications (queue_number, sent_at) VALUES (:queue_number, NOW())',
        );
        $statement->execute([':queue_number' => $queueNumber]);
    }

    public function hasNotificationRecord(string $queueNumber): bool
    {
        $statement = $this->pdo->prepare(
            'SELECT 1 FROM notifications WHERE queue_number = :queue_number LIMIT 1',
        );
        $statement->execute([':queue_number' => $queueNumber]);

        return $statement->fetchColumn() !== false;
    }

    public function logAction(string $action): void
    {
        $statement = $this->pdo->prepare(
            'INSERT INTO logs (action, created_at) VALUES (:action, NOW())',
        );
        $statement->execute([':action' => $action]);
    }
}

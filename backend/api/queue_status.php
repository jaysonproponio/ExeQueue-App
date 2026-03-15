<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('GET');

try {
    $queueNumber = isset($_GET['queue_number']) ? trim((string) $_GET['queue_number']) : null;
    $studentName = isset($_GET['student_name']) ? trim((string) $_GET['student_name']) : null;
    jsonResponse($queueService->getQueueStatus($queueNumber, $studentName));
} catch (RuntimeException $exception) {
    jsonResponse(
        [
            'success' => false,
            'message' => $exception->getMessage(),
        ],
        404,
    );
} catch (Throwable $exception) {
    jsonResponse(
        [
            'success' => false,
            'message' => $exception->getMessage(),
        ],
        500,
    );
}

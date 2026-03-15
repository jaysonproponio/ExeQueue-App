<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('POST');

try {
    $payload = requestData();
    $processedBy = trim((string) ($payload['processed_by'] ?? 'cashier_1'));
    $response = $queueService->nextQueue($processedBy);
    $response['notification_summary'] = $queueNotificationDispatcher
        ->dispatchThresholdNotifications(5);
    jsonResponse($response);
} catch (Throwable $exception) {
    jsonResponse(
        [
            'success' => false,
            'message' => $exception->getMessage(),
        ],
        500,
    );
}

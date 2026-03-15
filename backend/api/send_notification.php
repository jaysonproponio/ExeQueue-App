<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('POST');

try {
    $payload = requestData();
    $threshold = (int) ($payload['threshold'] ?? 5);
    jsonResponse($queueNotificationDispatcher->dispatchThresholdNotifications($threshold));
} catch (Throwable $exception) {
    jsonResponse(
        [
            'success' => false,
            'message' => $exception->getMessage(),
        ],
        500,
    );
}

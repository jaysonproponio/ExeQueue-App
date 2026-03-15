<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('POST');

try {
    $response = $queueService->skipQueue();
    $response['notification_summary'] = $queueNotificationDispatcher
        ->dispatchThresholdNotifications(5);
    jsonResponse($response);
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

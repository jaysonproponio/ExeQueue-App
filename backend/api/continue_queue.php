<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('POST');

try {
    $payload = requestData();
    $queueNumber = isset($payload['queue_number'])
        ? trim((string) $payload['queue_number'])
        : null;
    jsonResponse($queueService->continueQueue($queueNumber));
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

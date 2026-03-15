<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('POST');

try {
    jsonResponse($queueService->skipQueue());
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

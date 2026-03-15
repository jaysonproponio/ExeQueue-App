<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('GET');

try {
    jsonResponse($queueService->getCurrentQueue());
} catch (Throwable $exception) {
    jsonResponse(
        [
            'success' => false,
            'message' => $exception->getMessage(),
        ],
        500,
    );
}

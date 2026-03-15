<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('POST');

try {
    $payload = requestData();
    $processedBy = trim((string) ($payload['processed_by'] ?? 'cashier_1'));
    jsonResponse($queueService->nextQueue($processedBy));
} catch (Throwable $exception) {
    jsonResponse(
        [
            'success' => false,
            'message' => $exception->getMessage(),
        ],
        500,
    );
}

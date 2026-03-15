<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('POST');

try {
    $response = $queueService->submitForm(requestData());
    jsonResponse($response, 201);
} catch (InvalidArgumentException $exception) {
    jsonResponse(
        [
            'success' => false,
            'message' => $exception->getMessage(),
        ],
        422,
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

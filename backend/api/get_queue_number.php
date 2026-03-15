<?php

declare(strict_types=1);

require_once __DIR__ . '/../bootstrap.php';

requireMethod('POST');

try {
    $payload = requestData();
    $studentName = trim((string) ($payload['student_name'] ?? ''));

    if ($studentName === '') {
        throw new InvalidArgumentException('student_name is required.');
    }

    jsonResponse($queueService->getQueueNumber($studentName));
} catch (InvalidArgumentException $exception) {
    jsonResponse(
        [
            'success' => false,
            'message' => $exception->getMessage(),
        ],
        422,
    );
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

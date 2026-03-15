<?php

declare(strict_types=1);

function jsonResponse(array $payload, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    exit;
}

function requestData(): array
{
    $rawBody = trim((string) file_get_contents('php://input'));

    if ($rawBody !== '') {
        $decoded = json_decode($rawBody, true);
        if (is_array($decoded)) {
            return $decoded;
        }
    }

    return $_POST;
}

function requireMethod(string $method): void
{
    if (strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET') !== strtoupper($method)) {
        jsonResponse(
            [
                'success' => false,
                'message' => 'Method not allowed.',
            ],
            405,
        );
    }
}

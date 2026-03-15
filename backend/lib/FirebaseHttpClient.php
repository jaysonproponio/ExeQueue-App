<?php

declare(strict_types=1);

final class FirebaseHttpClient
{
    public function postForm(string $url, array $headers, array $body): array
    {
        return $this->send(
            $url,
            array_merge($headers, ['Content-Type: application/x-www-form-urlencoded']),
            http_build_query($body),
        );
    }

    public function postJson(string $url, array $headers, array $body): array
    {
        return $this->send(
            $url,
            array_merge($headers, ['Content-Type: application/json; charset=utf-8']),
            json_encode($body, JSON_THROW_ON_ERROR),
        );
    }

    private function send(string $url, array $headers, string $body): array
    {
        if (!extension_loaded('curl')) {
            throw new RuntimeException('PHP cURL extension is required for Firebase Cloud Messaging.');
        }

        $handle = curl_init($url);
        if ($handle === false) {
            throw new RuntimeException('Unable to initialize HTTP client for Firebase Cloud Messaging.');
        }

        curl_setopt_array(
            $handle,
            [
                CURLOPT_POST => true,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => $headers,
                CURLOPT_POSTFIELDS => $body,
                CURLOPT_TIMEOUT => 15,
            ],
        );

        $responseBody = curl_exec($handle);
        $statusCode = (int) curl_getinfo($handle, CURLINFO_HTTP_CODE);
        $curlError = curl_error($handle);
        curl_close($handle);

        if ($responseBody === false) {
            throw new RuntimeException(
                $curlError !== ''
                    ? $curlError
                    : 'Firebase Cloud Messaging request failed.',
            );
        }

        return [
            'status_code' => $statusCode,
            'body' => (string) $responseBody,
        ];
    }
}

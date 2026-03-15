<?php

declare(strict_types=1);

final class FirebaseAccessTokenProvider
{
    private ?string $cachedAccessToken = null;
    private int $expiresAtUnix = 0;

    public function __construct(
        private readonly FirebaseServiceAccount $serviceAccount,
        private readonly FirebaseHttpClient $httpClient,
    ) {
    }

    public function getAccessToken(): string
    {
        if ($this->cachedAccessToken !== null && time() < $this->expiresAtUnix - 60) {
            return $this->cachedAccessToken;
        }

        $response = $this->httpClient->postForm(
            'https://oauth2.googleapis.com/token',
            [],
            [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $this->buildAssertion(),
            ],
        );

        $decoded = json_decode($response['body'], true);
        if (
            $response['status_code'] < 200 ||
            $response['status_code'] >= 300 ||
            !is_array($decoded) ||
            !isset($decoded['access_token'], $decoded['expires_in'])
        ) {
            throw new RuntimeException(
                'Unable to obtain a Firebase access token. ' . $response['body'],
            );
        }

        $this->cachedAccessToken = (string) $decoded['access_token'];
        $this->expiresAtUnix = time() + (int) $decoded['expires_in'];

        return $this->cachedAccessToken;
    }

    private function buildAssertion(): string
    {
        $issuedAtUnix = time();
        $header = [
            'alg' => 'RS256',
            'typ' => 'JWT',
        ];
        $payload = [
            'iss' => $this->serviceAccount->clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $issuedAtUnix,
            'exp' => $issuedAtUnix + 3600,
        ];
        $unsignedToken = $this->encodeSegment($header) . '.' . $this->encodeSegment($payload);
        $signature = '';
        $privateKey = openssl_pkey_get_private($this->serviceAccount->privateKey);
        if ($privateKey === false) {
            throw new RuntimeException('The Firebase private key is invalid.');
        }
        $signed = openssl_sign($unsignedToken, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        openssl_free_key($privateKey);
        if ($signed !== true) {
            throw new RuntimeException('Unable to sign the Firebase access token assertion.');
        }

        return $unsignedToken . '.' . $this->encodeBase64Url($signature);
    }

    private function encodeSegment(array $value): string
    {
        return $this->encodeBase64Url(json_encode($value, JSON_THROW_ON_ERROR));
    }

    private function encodeBase64Url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}

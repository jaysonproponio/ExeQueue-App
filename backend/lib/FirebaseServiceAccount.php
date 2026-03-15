<?php

declare(strict_types=1);

final class FirebaseServiceAccount
{
    public function __construct(
        public readonly string $projectId,
        public readonly string $clientEmail,
        public readonly string $privateKey,
    ) {
    }

    public static function tryFromEnvironment(): ?self
    {
        $credentialsPath = trim((string) (getenv('GOOGLE_APPLICATION_CREDENTIALS') ?: ''));
        if ($credentialsPath !== '') {
            return self::tryFromJsonFile($credentialsPath);
        }

        $projectId = trim((string) (getenv('FIREBASE_PROJECT_ID') ?: ''));
        $clientEmail = trim((string) (getenv('FIREBASE_CLIENT_EMAIL') ?: ''));
        $privateKey = trim((string) (getenv('FIREBASE_PRIVATE_KEY') ?: ''));
        if ($projectId === '' || $clientEmail === '' || $privateKey === '') {
            return null;
        }

        return new self(
            $projectId,
            $clientEmail,
            self::normalizePrivateKey($privateKey),
        );
    }

    private static function tryFromJsonFile(string $credentialsPath): ?self
    {
        if (!is_file($credentialsPath) || !is_readable($credentialsPath)) {
            return null;
        }

        $decoded = json_decode((string) file_get_contents($credentialsPath), true);
        if (!is_array($decoded)) {
            return null;
        }

        $projectId = trim((string) ($decoded['project_id'] ?? ''));
        $clientEmail = trim((string) ($decoded['client_email'] ?? ''));
        $privateKey = trim((string) ($decoded['private_key'] ?? ''));
        if ($projectId === '' || $clientEmail === '' || $privateKey === '') {
            return null;
        }

        return new self(
            $projectId,
            $clientEmail,
            self::normalizePrivateKey($privateKey),
        );
    }

    private static function normalizePrivateKey(string $privateKey): string
    {
        return str_replace('\n', "\n", $privateKey);
    }
}

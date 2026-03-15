<?php

declare(strict_types=1);

final class Database
{
    public static function connection(): PDO
    {
        static $pdo = null;

        if ($pdo instanceof PDO) {
            return $pdo;
        }

        $host = getenv('DB_HOST') ?: '127.0.0.1';
        $database = getenv('DB_NAME') ?: 'exequeue';
        $username = getenv('DB_USER') ?: 'root';
        $password = getenv('DB_PASS') ?: '';
        $charset = 'utf8mb4';

        $dsn = sprintf(
            'mysql:host=%s;dbname=%s;charset=%s',
            $host,
            $database,
            $charset,
        );

        $pdo = new PDO(
            $dsn,
            $username,
            $password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ],
        );

        return $pdo;
    }
}

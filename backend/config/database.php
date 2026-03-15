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

        self::migrate($pdo, $database);

        return $pdo;
    }

    private static function migrate(PDO $pdo, string $database): void
    {
        if (!self::tableExists($pdo, $database, 'queues')) {
            return;
        }

        if (!self::columnExists($pdo, $database, 'queues', 'student_id')) {
            $pdo->exec(
                'ALTER TABLE queues ADD COLUMN student_id VARCHAR(40) NULL AFTER student_name',
            );
        }
    }

    private static function tableExists(
        PDO $pdo,
        string $database,
        string $tableName,
    ): bool {
        $statement = $pdo->prepare(
            'SELECT 1
             FROM information_schema.tables
             WHERE table_schema = :database
               AND table_name = :table_name
             LIMIT 1',
        );
        $statement->execute(
            [
                ':database' => $database,
                ':table_name' => $tableName,
            ],
        );

        return $statement->fetchColumn() !== false;
    }

    private static function columnExists(
        PDO $pdo,
        string $database,
        string $tableName,
        string $columnName,
    ): bool {
        $statement = $pdo->prepare(
            'SELECT 1
             FROM information_schema.columns
             WHERE table_schema = :database
               AND table_name = :table_name
               AND column_name = :column_name
             LIMIT 1',
        );
        $statement->execute(
            [
                ':database' => $database,
                ':table_name' => $tableName,
                ':column_name' => $columnName,
            ],
        );

        return $statement->fetchColumn() !== false;
    }
}

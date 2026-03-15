<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/lib/ApiResponse.php';
require_once __DIR__ . '/lib/QueueRepository.php';
require_once __DIR__ . '/lib/QueueService.php';

$queueRepository = new QueueRepository(Database::connection());
$queueService = new QueueService($queueRepository);

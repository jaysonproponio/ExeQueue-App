<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/lib/ApiResponse.php';
require_once __DIR__ . '/lib/FirebaseServiceAccount.php';
require_once __DIR__ . '/lib/FirebaseHttpClient.php';
require_once __DIR__ . '/lib/FirebaseAccessTokenProvider.php';
require_once __DIR__ . '/lib/FirebaseMessagingClient.php';
require_once __DIR__ . '/lib/QueueRepository.php';
require_once __DIR__ . '/lib/QueueNotificationDispatcher.php';
require_once __DIR__ . '/lib/QueueService.php';

$queueRepository = new QueueRepository(Database::connection());
$queueService = new QueueService($queueRepository);
$firebaseServiceAccount = FirebaseServiceAccount::tryFromEnvironment();
$firebaseHttpClient = new FirebaseHttpClient();
$firebaseAccessTokenProvider = $firebaseServiceAccount instanceof FirebaseServiceAccount
    ? new FirebaseAccessTokenProvider($firebaseServiceAccount, $firebaseHttpClient)
    : null;
$firebaseMessagingClient = $firebaseAccessTokenProvider instanceof FirebaseAccessTokenProvider
    ? new FirebaseMessagingClient(
        $firebaseServiceAccount,
        $firebaseAccessTokenProvider,
        $firebaseHttpClient,
    )
    : null;
$queueNotificationDispatcher = new QueueNotificationDispatcher(
    $queueService,
    $queueRepository,
    $firebaseMessagingClient,
);

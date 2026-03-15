<?php

declare(strict_types=1);

final class FirebaseMessagingClient
{
    private const QUEUE_ALERT_CHANNEL_ID = 'queue_alerts';
    private const QUEUE_ALERT_SOUND_NAME = 'queue_alert_sound';
    private const IOS_DEFAULT_SOUND_NAME = 'default';

    public function __construct(
        private readonly FirebaseServiceAccount $serviceAccount,
        private readonly FirebaseAccessTokenProvider $accessTokenProvider,
        private readonly FirebaseHttpClient $httpClient,
    ) {
    }

    public function sendQueueAlert(array $notification): string
    {
        $response = $this->httpClient->postJson(
            $this->buildEndpoint(),
            [
                'Authorization: Bearer ' . $this->accessTokenProvider->getAccessToken(),
            ],
            [
                'message' => $this->buildMessage($notification),
            ],
        );

        $decoded = json_decode($response['body'], true);
        if (
            $response['status_code'] < 200 ||
            $response['status_code'] >= 300 ||
            !is_array($decoded) ||
            !isset($decoded['name'])
        ) {
            throw new RuntimeException(
                'Firebase Cloud Messaging send failed. ' . $response['body'],
            );
        }

        return (string) $decoded['name'];
    }

    private function buildEndpoint(): string
    {
        return sprintf(
            'https://fcm.googleapis.com/v1/projects/%s/messages:send',
            $this->serviceAccount->projectId,
        );
    }

    private function buildMessage(array $notification): array
    {
        $queueNumber = trim((string) ($notification['queue_number'] ?? ''));
        $title = trim((string) ($notification['title'] ?? 'ExeQueue Alert'));
        $body = trim((string) ($notification['body'] ?? 'Your queue is approaching.'));
        $distance = (string) ($notification['distance'] ?? '');

        return [
            'topic' => trim((string) ($notification['topic'] ?? '')),
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => [
                'type' => 'queue_alert',
                'queue_number' => $queueNumber,
                'distance' => $distance,
                'title' => $title,
                'body' => $body,
            ],
            'android' => [
                'priority' => 'HIGH',
                'ttl' => '900s',
                'notification' => [
                    'channel_id' => self::QUEUE_ALERT_CHANNEL_ID,
                    'sound' => self::QUEUE_ALERT_SOUND_NAME,
                    'default_vibrate_timings' => true,
                    'visibility' => 'PUBLIC',
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                ],
                'payload' => [
                    'aps' => [
                        'sound' => self::IOS_DEFAULT_SOUND_NAME,
                        'badge' => 1,
                    ],
                ],
            ],
        ];
    }
}

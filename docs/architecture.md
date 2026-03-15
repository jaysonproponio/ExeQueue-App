# ExeQueue Architecture

## Mobile application

- Flutter shell: a single `Scaffold` with exactly 3 bottom navigation tabs.
- `My Queue`: shows queue number, now serving, position, estimated wait time, queue progress, and status.
- `Scan QR`: uses `mobile_scanner` for QR intake, includes an animated scanning line, and exposes a manual join button without adding a fourth tab.
- `Live Board`: polls the current queue endpoint every 5 seconds and renders a large realtime board.
- Push notifications: the mobile app subscribes to an FCM topic named `queue_<queue_number>` after joining the queue.

## Web dashboard and displays

- `web/dashboard.html`: cashier dashboard with sidebar navigation, live queue controls, queue table, and JavaScript speech announcements.
- `web/qr-display.html`: monitor/tablet view that shows a large QR card and current queue.
- `web/queue-display.html`: TV-friendly live board for `NOW SERVING` and the next three queue numbers.
- `web/script.js`: contains a UI-state simulator for local demo mode and uses `speechSynthesis` to announce called queues.

## PHP API architecture

- `backend/bootstrap.php`: shared bootstrap that wires the PDO connection, response helpers, repository, and queue service.
- `backend/config/database.php`: PDO factory using environment variables `DB_HOST`, `DB_NAME`, `DB_USER`, and `DB_PASS`.
- `backend/lib/QueueRepository.php`: database reads and writes.
- `backend/lib/QueueService.php`: queue rules, queue progression, skipped-queue handling, and notification payload generation.
- `backend/api/*.php`: endpoint-specific request handling for the required routes.

## Queue algorithm

1. Student scans the cashier QR code or uses manual join from the mobile app.
2. `POST /join_queue` creates the next sequential queue number, defaults the status to `WAITING`, and logs the action.
3. Cashier presses `NEXT`, which marks the current `CALLED` queue as `DONE`, inserts a transaction record, then promotes the oldest `WAITING` queue to `CALLED`.
4. If a student is absent, `POST /skip_queue` changes the active queue to `SKIPPED` and immediately calls the next waiting student.
5. If the skipped student returns, `POST /continue_queue` sets that record back to `WAITING` and refreshes `created_at` so it moves to the next available waiting slot.
6. `GET /queue_status` calculates `people_ahead` from the queue number gap between the student queue and the live `now_serving` queue.

## Notification logic

- Trigger point: after each `next_queue` or `skip_queue`, call `send_notification.php`.
- The service checks all `WAITING` queues that are within 5 sequence numbers of the current `CALLED` queue.
- For each qualifying queue:
  - a notification record is inserted into `notifications`
  - a Firebase topic payload is prepared for `queue_<queue_number>`
  - the suggested message is: `Your queue number A021 is approaching. Please prepare to proceed to the cashier.`
- Client behavior:
  - subscribe to the queue topic after join
  - show a high-priority FCM notification
  - vibrate the device on receipt

## Voice announcement

- The cashier dashboard and TV board use the browser `SpeechSynthesis` API.
- When `now_serving` changes, the browser announces:
  `Queue number A021 please proceed to the cashier window.`

## Recommended next integration steps

1. Add actual Firebase configuration files to the Flutter app and replace the topic-payload stub with a server-side FCM sender.
2. Serve `web/` and `backend/` from the same PHP host so the dashboard can fetch real queue data instead of demo state.
3. Add authentication for admin routes and hash real cashier passwords with PHP `password_hash`.
4. Add a cron job or event trigger for stale `CALLED` queues so staff can see when 1 minute has elapsed before skipping.

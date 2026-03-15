# ExeQueue

ExeQueue is a university cashier queue management system scaffold with a Flutter student app, a PHP/MySQL backend, and responsive web screens for cashier staff and public queue displays.

## Project structure

- `mobile/`: Flutter mobile UI with exactly 3 bottom navigation tabs: My Queue, Scan QR, and Live Board.
- `web/`: cashier dashboard, QR display, and queue display monitor pages.
- `backend/`: PHP API endpoints, queue service layer, and PDO-based data access.
- `database/`: MySQL schema for queues, transactions, admins, notifications, and logs.
- `docs/architecture.md`: queue flow, notification logic, and system architecture.

## Included outputs

- Flutter navigation structure and themed UI scaffold
- Admin dashboard layout
- QR display screen
- Queue display screen
- MySQL schema
- PHP API architecture and endpoint stubs
- Queue progression algorithm
- Firebase notification topic strategy
- Voice announcement integration via JavaScript `speechSynthesis`

## Notes

- Flutter SDK is not installed in this environment, so the mobile app was scaffolded but not executed or formatted with Flutter tooling.
- PHP CLI is available, so backend files can be syntax-checked locally.

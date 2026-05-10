# SalonEase

SalonEase is a role-based salon booking demo product.

- Customers can register, log in, browse services, book an appointment, apply coupons, complete a dummy payment, and manage bookings.
- Admins are salon owners or shop keepers. They log in from the same login page and get an owner dashboard for stats, booking status updates, and adding salon services.
- Payments are demo-only. Clicking **Complete Demo Payment** records the booking without charging real money.

## Tech Stack

- Flutter app in `lib/`
- Node.js/Express backend in `backend/`
- SQLite database created locally at `backend/data/salonease.sqlite`
- JWT authentication with `admin` and `user` roles

Use Node.js `22.5.0` or newer because the backend uses the built-in `node:sqlite` module.

## Demo Accounts

The database seeds these accounts automatically on first backend start:

| Role | Email | Password |
| --- | --- | --- |
| Admin / shop owner | `admin@salonease.com` | `admin123` |
| Customer | `user@salonease.com` | `user123` |

The login page also has demo buttons to fill these credentials.

## Backend Setup

```bash
cd backend
npm install
copy .env.example .env
npm run dev
```

Backend runs on:

```text
http://localhost:5000
```

Useful backend commands:

```bash
npm start
npm run dev
npm run db:reset
```

`npm run db:reset` deletes and recreates the local SQLite database with demo users, services, and coupons.

## Flutter Setup

From the project root:

```bash
flutter pub get
flutter run
```

Recommended check before running or deploying:

```bash
flutter analyze
```

Expected result:

```text
No issues found!
```

The API base URL is configured in:

```text
lib/core/constants/app_strings.dart
```

Defaults:

- Web/Desktop/iOS simulator: `http://localhost:5000`
- Android emulator: `http://10.0.2.2:5000`

## Main Features

- Single login page with role-based routing
- Admin dashboard for salon owners
- Admin booking status management
- Admin service creation
- Customer home page with services, search, filters, and wishlist flow
- Booking date, slot, add-on, coupon, and bill summary flow
- Dummy payment completion
- Customer booking history and cancellation
- Profile/settings screens

## Coupons

Seeded coupons:

- `FIRST20`
- `BEAUTY20`
- `NEWLOOK`

## Deployment Notes

For a live demo similar to Hugging Face Spaces:

1. Deploy the backend as a Node.js service.
2. Set backend environment variables from `backend/.env.example`.
3. Build the Flutter web app.
4. Serve the Flutter web build as static files.
5. Update `AppStrings.apiBaseUrl` to the deployed backend URL before building.

For Hugging Face Spaces specifically, use a Docker Space or split deployment:

- Host the Express backend in a Node-capable container.
- Serve Flutter web output from the same container or another static host.
- Keep `backend/data/` persistent if you want SQLite data to survive restarts.

## Current Verification

- `flutter pub get` completed successfully.
- `flutter analyze` completed with no issues.
- Backend JavaScript syntax checks passed for the main server, database config, auth controller, and booking controller.
- Local Node version checked: `v22.18.0`.

## Git Hygiene

Generated and local-only files are ignored, including:

- Flutter `build/` and `.dart_tool/`
- `backend/node_modules/`
- `backend/.env`
- SQLite files under `backend/data/`
- uploaded local files under `backend/uploads/`

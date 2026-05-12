# SalonEase

SalonEase is a role-based salon booking app built with Flutter, Express, and SQLite.

- Customers can register, log in, browse services, book appointments, apply coupons, complete a demo payment, and manage bookings.
- Admins can view shop stats, confirm or cancel bookings, see the full customer list, and add salon services.
- The AI Style Advisor can call Hugging Face Inference Providers from the backend when `HF_TOKEN` is configured, with a local fallback for development.

## Tech Stack

- Flutter app in `lib/`
- Node.js/Express backend in `backend/`
- SQLite database stored locally in `backend/data/`
- JWT authentication with `admin` and `user` roles

Use Node.js `22.5.0` or newer because the backend uses the built-in `node:sqlite` module.

## Demo Accounts

The database seeds these accounts automatically on first backend start:

| Role | Email | Password |
| --- | --- | --- |
| Admin / shop owner | `admin@salonease.com` | `admin123` |
| Customer | `user@salonease.com` | `user123` |

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
npm run db:show
```

If port `5000` is already in use on Windows:

```powershell
netstat -ano | findstr :5000
Stop-Process -Id <PID>
```

## Database Files

The local database files are:

```text
backend/data/salonease.sqlite
backend/data/salonease.sqlite-shm
backend/data/salonease.sqlite-wal
```

The main database is `salonease.sqlite`. The `-wal` and `-shm` files are SQLite write-ahead-log sidecar files and are normal while the backend is running.

To reset all local data and recreate demo users, services, and coupons:

```bash
cd backend
npm run db:reset
```

To see stored data from the terminal:

```bash
cd backend
npm run db:show
```

You can also open `backend/data/salonease.sqlite` with a SQLite viewer such as DB Browser for SQLite.

## Flutter Setup

From the project root:

```bash
flutter pub get
flutter run
```

For Android emulator testing, keep the backend running on your computer. The app automatically uses:

```text
http://10.0.2.2:5000
```

For a physical Android phone, build with your computer LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:5000
flutter build apk --dart-define=API_BASE_URL=http://YOUR_LAN_IP:5000
```

## Live Hugging Face AI

The Flutter app calls the backend endpoint:

```text
POST /api/ai/style-advisor
```

To enable live Hugging Face responses, edit `backend/.env`:

```env
HF_TOKEN=hf_your_token_here
HF_MODEL=openai/gpt-oss-120b:cerebras
HF_BASE_URL=https://router.huggingface.co/v1/chat/completions
```

Create a Hugging Face token with Inference Providers permission, then restart the backend. The API style follows Hugging Face's OpenAI-compatible Inference Providers router: https://huggingface.co/docs/inference-providers/en/tasks/chat-completion

If `HF_TOKEN` is empty, the app still works using the built-in local style recommendation fallback.

## Main Features

- Single login page with role-based routing
- Admin dashboard for salon owners
- Admin customer list
- Admin booking status management
- Admin service creation
- Customer home page with services, search, filters, and wishlist flow
- Booking date, slot, add-on, coupon, and bill summary flow
- Dummy payment completion
- Customer booking history and cancellation
- Profile/settings screens
- AI Style Advisor with Hugging Face backend integration

## Coupons

Seeded coupons:

- `FIRST20`
- `BEAUTY20`
- `NEWLOOK`

## Git Hygiene

Generated and local-only files are ignored, including:

- Flutter `build/` and `.dart_tool/`
- `backend/node_modules/`
- `backend/.env`
- SQLite files under `backend/data/`
- uploaded local files under `backend/uploads/`

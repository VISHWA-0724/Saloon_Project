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

## Hugging Face Backend Deployment

Create a Hugging Face **Docker Space** for the backend. The deploy files are inside `backend/`:

```text
backend/Dockerfile
backend/.dockerignore
backend/README.md
```

Add these as **Secrets** in Space Settings:

```text
JWT_SECRET=<generated random string>
JWT_REFRESH_SECRET=<generated random string>
HF_TOKEN=hf_your_huggingface_token
```

Generate the JWT strings locally:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

Add these as **Variables** in Space Settings:

```text
PORT=7860
SQLITE_PATH=/data/salonease.sqlite
CLIENT_URL=https://YOUR_USERNAME-YOUR_SPACE_NAME.hf.space
NODE_ENV=production
HF_MODEL=openai/gpt-oss-120b:cerebras
HF_BASE_URL=https://router.huggingface.co/v1/chat/completions
```

Push only the backend folder to the Space:

```powershell
git clone https://huggingface.co/spaces/YOUR_USERNAME/YOUR_SPACE_NAME salonease-hf-backend
Copy-Item -Path .\backend\* -Destination .\salonease-hf-backend -Recurse -Force -Exclude node_modules,data,uploads,.env
cd salonease-hf-backend
git add .
git commit -m "Deploy SalonEase backend"
git push
```

After it deploys, your backend URL will be:

```text
https://YOUR_USERNAME-YOUR_SPACE_NAME.hf.space
```

Build the Android app against that backend:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_USERNAME-YOUR_SPACE_NAME.hf.space
```

PS C:\Users\essai\Downloads\salonease-hf-backend> node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
>> node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
>> 
d58c087e7f8a1d485934cb00f7a6531d45901754cc3befb3ad5ec5013b12240a306b08d2aa33fc3f6d0d051e40cf1e7c
a2bb0e5d8e1c25b8804a159833e1f1242c3297ea8e4a4600b83b8fb4967dae3a08aa5d3a0f935d0f58c6cba24bab2635
PS C:\Users\essai\Downloads\salonease-hf-backend> 


Hugging Face Docker Spaces expose the port configured in the Space README metadata, and Spaces secrets/variables are available to the container as environment variables. Docker Space data is temporary unless you enable persistent storage; with persistent storage, `/data` is the correct place for SQLite.

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

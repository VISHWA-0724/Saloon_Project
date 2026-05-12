---
title: SalonEase Backend
sdk: docker
app_port: 7860
---

# SalonEase Backend

Express + SQLite backend for the SalonEase Flutter app.

## Required Space Secrets

Add these in the Hugging Face Space **Settings** page:

- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `HF_TOKEN`

## Recommended Space Variables

- `PORT=7860`
- `SQLITE_PATH=/data/salonease.sqlite`
- `CLIENT_URL=https://YOUR_USERNAME-YOUR_SPACE_NAME.hf.space`
- `NODE_ENV=production`
- `HF_MODEL=openai/gpt-oss-120b:cerebras`
- `HF_BASE_URL=https://router.huggingface.co/v1/chat/completions`

The database is stored at `/data/salonease.sqlite`. Add persistent storage to the Space if you want SQLite data to survive restarts.

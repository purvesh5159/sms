# Society Mobile (Expo React Native)

## Prerequisites
- Node 18+
- Expo CLI: `npm i -g expo`
- Android Studio or Xcode for device/simulator

## Run
```bash
cd mobile
npm install
npm start
```
Scan the QR in Expo Go (device) or press `a`/`i` to run on Android/iOS.

## Backend
- API base: `http://localhost:3001/api` (edit in `src/lib/api.ts` if needed)
- Requires headers: `Authorization: Bearer <token>`, `X-Society-Id: <id>`

## Features (MVP)
- Login (password or dev-login)
- Role-based tabs
- View Towers, Flats
- View/Create Complaints

Next steps: payments flow, bookings, visitors, polls, accounting dashboards.
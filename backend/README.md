# Society Backend (Express + Sequelize + PostgreSQL)

## Setup
```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

Ensure the Postgres container from the project root is running (see root README).

## Environment
- `PORT`: default 3001
- `JWT_SECRET`, `JWT_EXPIRES_IN`
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`
- `ALLOW_DEV_LOGIN`: enable /api/auth/dev-login

## Auth
- POST `/api/auth/login` with `{ email, password, societyId? }` to receive JWT; societyId optional if user has one membership.
- For development, POST `/api/auth/dev-login` with `{ email, societyId? }` to get a token without password when enabled.

Attach:
- Header `Authorization: Bearer <token>`
- Header `X-Society-Id: <societyId>` for scoping

## Permissions
RBAC is enforced via `society_memberships` -> `society_user_roles` -> `role_permissions` -> `permissions`.

## Sample API
- GET `/api/towers` (requires `towers:read`)
- POST `/api/towers` body `{ name, address?, num_floors? }` (requires `towers:create`)
- GET `/api/flats` (requires `flats:read`)
- POST `/api/flats` body `{ towerId, number, floor? }` (requires `flats:create`)
- GET `/api/complaints` (requires `complaints:read`)
- POST `/api/complaints` body `{ flatId, category, description, priority? }` (requires `complaints:create`)
- PATCH `/api/complaints/:id/status` body `{ status }` (requires `complaints:update`)

## Quick test (dev-login)
```bash
# Get token as admin for Green Meadows
curl -s http://localhost:3001/api/auth/dev-login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@society.local","societyId":1}' | jq -r .token

# List towers
curl -s http://localhost:3001/api/towers \
  -H "Authorization: Bearer $TOKEN" \
  -H 'X-Society-Id: 1' | jq
```
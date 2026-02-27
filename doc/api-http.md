# HTTP API (MVP)

## Purpose

Define non-realtime REST endpoints that complement the WebSocket protocol.

- REST handles auth, bootstrap data, and read-heavy UI calls.
- WebSocket handles realtime simulation and gameplay state.

## Base

- Base URL: `/api/v1`
- Auth: `Authorization: Bearer <token>` for protected endpoints
- Content type: `application/json`

## Error Format

All error responses:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message"
  }
}
```

Common HTTP status usage:
- `200` success read
- `201` created
- `400` validation error
- `401` unauthorized
- `403` forbidden
- `404` not found
- `409` conflict
- `429` rate limit

## Auth

Auth is database-backed for MVP.

- User credentials are persisted in PostgreSQL (`players` table).
- `POST /users` creates a new user/player row with a hashed password.
- `POST /auth/register` inserts a new player row with a hashed password.
- `POST /auth/login` validates against stored password hash (no in-memory or hard-coded users).
- JWT subject (`sub`) maps to `players.id` and must resolve to an existing player for protected routes.

### `POST /users`

Create new user (account signup).

Request:
```json
{
  "username": "captain_neo",
  "password": "strong_password"
}
```

Response `201`:
```json
{
  "player_id": "p_123",
  "username": "captain_neo"
}
```

Rules:
- username 3–32 chars, `[a-zA-Z0-9_]+`
- password minimum length 8
- username must be unique (409 on conflict)
- server stores password hash only (never plaintext)

### `POST /auth/register`

Create account.

Note:
- `POST /auth/register` is kept as compatibility alias for `POST /users` during MVP.

Request:
```json
{
  "username": "captain_neo",
  "password": "strong_password"
}
```

Response `201`:
```json
{
  "player_id": "p_123",
  "username": "captain_neo"
}
```

Rules:
- username 3–32 chars, `[a-zA-Z0-9_]+`
- password minimum length 8
- username must be unique (409 on conflict)
- server stores password hash only (never plaintext)

### `POST /auth/login`

Issue JWT/session token.

Request:
```json
{
  "username": "captain_neo",
  "password": "strong_password"
}
```

Response `200`:
```json
{
  "access_token": "jwt_token",
  "token_type": "Bearer",
  "expires_in": 3600,
  "player_id": "p_123"
}
```

Validation behavior:
- Lookup by `username` in database.
- Verify password against stored hash.
- Return `401` for invalid username/password.

### `POST /auth/refresh`

Refresh short-lived access token (if refresh flow enabled).

Validation behavior:
- Verify refresh token is valid and mapped to an existing player.
- Reject revoked/expired refresh token with `401`.

## Player + Ship

### `GET /me`

Returns account + active ship summary.

Response `200`:
```json
{
  "player": {
    "id": "p_123",
    "username": "captain_neo",
    "credits": 5000,
    "reputation": 0
  },
  "ship": {
    "id": "s_987",
    "ship_class": "starter_freighter",
    "hull_current": 100,
    "hull_max": 100,
    "fuel_current": 100,
    "fuel_max": 100,
    "cargo_capacity": 30
  }
}
```

### `GET /me/cargo`

Returns current cargo hold contents.

Response `200`:
```json
{
  "ship_id": "s_987",
  "cargo": [
    { "commodity_id": "food", "quantity": 10 },
    { "commodity_id": "water", "quantity": 2 }
  ],
  "used_capacity": 12,
  "total_capacity": 30
}
```

## World + Market

### `GET /world/locations`

List planets/stations in single system.

Response `200`:
```json
{
  "system_id": "sol-1",
  "locations": [
    {
      "id": "earth-orbit-station",
      "name": "Earth Orbit Station",
      "type": "station",
      "x": 1200,
      "y": 400,
      "security_level": 90,
      "services": { "market": true, "repair": true, "refuel": true }
    }
  ]
}
```

### `GET /market/{location_id}`

Get market prices for one location.

Response `200`:
```json
{
  "location_id": "earth-orbit-station",
  "updated_at": "2026-02-27T10:00:00Z",
  "items": [
    { "commodity_id": "food", "buy": 11, "sell": 9, "stock_qty": 120 },
    { "commodity_id": "ore", "buy": 22, "sell": 18, "stock_qty": 60 }
  ]
}
```

### `GET /commodities`

List tradeable commodity metadata.

Response `200`:
```json
{
  "commodities": [
    { "id": "food", "name": "Food", "unit_mass": 1, "base_price": 10 },
    { "id": "ore", "name": "Ore", "unit_mass": 2, "base_price": 20 }
  ]
}
```

## Economy + History

### `GET /me/transactions?limit=50&offset=0`

Paginated transaction history.

Response `200`:
```json
{
  "items": [
    {
      "id": "tx_1",
      "tx_type": "sell",
      "location_id": "mars-orbit-station",
      "commodity_id": "food",
      "quantity": 10,
      "unit_price": 15,
      "total_amount": 150,
      "created_at": "2026-02-27T10:15:01Z"
    }
  ],
  "total": 1
}
```

### `GET /leaderboard/credits?limit=20`

Top players by credits.

Response `200`:
```json
{
  "items": [
    { "rank": 1, "player_id": "p_5", "username": "vanta", "credits": 99999 },
    { "rank": 2, "player_id": "p_9", "username": "nova", "credits": 85000 }
  ]
}
```

## Session Bootstrap

### `GET /session/bootstrap`

Initial payload client can fetch before opening WebSocket.

Response `200`:
```json
{
  "protocol_version": 1,
  "system_id": "sol-1",
  "ws_url": "wss://example.com/ws",
  "player": { "id": "p_123", "username": "captain_neo" },
  "ship": { "id": "s_987", "ship_class": "starter_freighter" }
}
```

## Security + Limits

- Passwords stored with strong hash (`argon2` or `bcrypt`).
- Rate limit on `/auth/login` and `/auth/register`.
- JWT expiry kept short; refresh token revocation supported if enabled.
- Input validation on all query/body params.

## Notes on Scope

- Trade mutations (`buy`, `sell`) remain WebSocket operations for gameplay consistency.
- Optional future HTTP admin endpoints are out of MVP scope.

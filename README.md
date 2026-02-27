# StarTrader

<u>WORK IN PROGRESS</u>

This project is currently under active development and subject to frequent changes.

StarTrader is a multiplayer 2D space trading game (web-based) with realtime ship control, PvE pirate encounters, and economy-driven gameplay in a single star system (`sol-1`).

## Current Project State

This repository currently includes:

- Backend API skeleton (FastAPI)
- PostgreSQL schema + world seed SQL
- Redis-backed login profile cache (24h cache-aside with sliding expiration)
- Containerized local development via Docker Compose
- Planning and implementation docs under `doc/`

## Architecture Overview

- **Client**: Web frontend (planned), realtime controls and rendering
- **API/Realtime**: Python FastAPI backend + WebSocket protocol (documented)
- **Persistence**: PostgreSQL for durable world/player data
- **Cache**: Redis for login/profile hydration performance

## Login Cache Flow (Implemented)

On login, user profile hydration follows a cache-aside flow:

1. Read Redis key: `player:profile:{player_id}`
2. If found, return cached profile and refresh TTL (sliding expiration)
3. If not found, read from PostgreSQL `players`
4. Cache in Redis for 24h (`LOGIN_PROFILE_CACHE_TTL_SECONDS`, default `86400`)

Internal endpoint:

- `POST /internal/auth/on-login`

## Getting Started (Docker)

### 1) Prepare environment

Create `.env` (or copy from `.env.example`) with at least:

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `DATABASE_URL`
- `REDIS_URL`
- `LOGIN_PROFILE_CACHE_TTL_SECONDS`
- `JWT_SECRET`

### 2) Start services

```bash
docker compose up --build
```

Services:

- `api` on port `8000`
- `db` (Postgres) on port `5432`
- `redis` on port `6379`

### 3) Health check

```bash
curl http://localhost:8000/health
```

Expected:

```json
{"status":"ok"}
```

## Running Tests (Docker)

### One command (PowerShell script)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-docker-tests.ps1
```

### VS Code task

- `Docker: Run Backend Tests`

### Stop test services

```powershell
powershell -ExecutionPolicy Bypass -File scripts/stop-docker-tests.ps1
```

Or VS Code task:

- `Docker: Stop Test Services`

## Repository Layout

```text
backend/                 # FastAPI app and services
doc/                     # Game design + technical docs + seeds
docker/                  # Dockerfiles, DB init SQL, operational notes
docker-compose.yml       # Local orchestration
scripts/                 # Utility scripts (test run/stop)
```

## Documentation Index

Start here for project design and contracts:

- `doc/README.md`

Important docs:

- Game/product vision: `doc/game-vision.md`
- MVP scope: `doc/mvp-scope.md`
- Technical architecture: `doc/technical-architecture.md`
- Realtime protocol: `doc/realtime-protocol.md`
- Data model: `doc/data-model.md`
- HTTP API: `doc/api-http.md`
- Login cache service: `doc/login-cache-service.md`
- Zone model + balancing: `doc/zone-model.md`, `doc/balance-rules.md`
- Seed files: `doc/seeds/`

## Notes

- Database init scripts under `docker/postgres/init` are executed only on first boot of a fresh Postgres volume.
- To fully reinitialize DB from SQL init scripts, run:

```bash
docker compose down -v
docker compose up --build
```

# Docker Notes

## One-time DB initialization behavior

The `db` service mounts SQL files from:

- `docker/postgres/init/001_schema.sql`
- `docker/postgres/init/002_seed.sql`
- `docker/postgres/init/003_seed_world.sql`
- `docker/postgres/init/004_seed_zones.sql`

`003_seed_world.sql` seeds locations, commodities, and market prices for Sol-1.
`004_seed_zones.sql` seeds Sol-1 zone profiles for free-flight risk/reward rules.

PostgreSQL executes files in `/docker-entrypoint-initdb.d` **only when `postgres_data` is empty** (first boot of a new volume).

### What happens on restart?

- `docker compose restart` or `docker compose down && docker compose up`:
  - Existing `postgres_data` volume is reused.
  - Init SQL files are **not** re-run.

### How to force a fresh initialization

If you intentionally want re-init from scratch:

```bash
docker compose down -v
docker compose up --build
```

This removes named volumes and creates a new empty `postgres_data` volume.

## Seed sanity check

After startup, run:

```bash
docker compose exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/verify-all.sql
```

Expected:

- every row returns `ok = t`
- sanity checks match expected counts
- integrity checks have `actual_value = 0`

## Integrity check

Run:

```bash
docker compose exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/integrity-check.sql
```

Expected result:

- All `issue_count` values are `0`.

Note: `verify-all.sql` is the preferred single-command check; `sanity-check.sql` and `integrity-check.sql` are kept for split troubleshooting.

## Run backend unit tests in Docker

Use the dedicated test service (runs `pytest -q` inside container):

```bash
docker compose run --rm api-tests
```

This runs tests against the same container image and environment variables as `api`, with `db` and `redis` available.

### One-command option (recommended)

From workspace root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-docker-tests.ps1
```

Or in VS Code run task:

- `Docker: Run Backend Tests`

### Stop services after tests

```powershell
powershell -ExecutionPolicy Bypass -File scripts/stop-docker-tests.ps1
```

Or in VS Code run task:

- `Docker: Stop Test Services`

## Login cache behavior in Docker

The login hydrate flow (`POST /internal/auth/on-login`) uses Redis cache-aside with optional sliding expiration.

- Cache key: `player:profile:{player_id}`
- TTL env var: `LOGIN_PROFILE_CACHE_TTL_SECONDS` (default `86400`)
- On Redis hit: returns cached profile and refreshes TTL (`EXPIRE`)
- On miss: loads from Postgres and writes to Redis with TTL

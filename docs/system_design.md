# System Design (WIP)

## 1) Problem framing

StarTrader needs a backend that supports a realtime multiplayer 2D trading/combat game in a single star system. The system must handle low-latency ship updates, durable player/economy state, and fast login hydration so active players can re-enter quickly.

## 2) Constraints

- Web-based client, Python backend.
- Single-system scope for MVP (sol-1), free-flight in 2D.
- Server-authoritative movement/combat to reduce cheating.
- Persistent player/economy data in Postgres.
- Login path should prefer Redis cache for recently active users (24h TTL, sliding refresh).
- Small team and iterative delivery: prefer clear, debuggable architecture over premature complexity.

## 3) Architecture overview

- API + realtime gateway: FastAPI service.
- Realtime transport: WebSocket for input/state sync.
- Persistent store: PostgreSQL (players, markets, zones, transactions).
- Cache: Redis for login profile hydration and short-lived hot data.
- Containerization: Docker Compose (`api`, `db`, `redis`, `api-tests`).

Data flow (login):
1. Auth flow resolves `player_id`.
2. Internal login hydrate endpoint checks Redis `player:profile:{player_id}`.
3. On hit, returns cached profile and refreshes TTL.
4. On miss, loads profile from Postgres and writes back to Redis.

## 4) Data model reasoning

- Postgres is the source of truth for all durable state.
- Core domain entities are normalized for consistency: players, locations, commodities, market_prices, zone_profiles.
- Transaction/event-style tables (e.g., transactions, combat logs) preserve traceability.
- Zone model is explicit in storage to keep free-flight risk/reward deterministic and tunable.
- Cache entries are derived, denormalized read models and can be regenerated from Postgres.

## 5) Realtime sync strategy

- Client sends intent (`thrust`, `turn`, `fire`) rather than trusted state.
- Server runs fixed-tick simulation and publishes `world.delta` frequently.
- Periodic `world.snapshot` corrects drift and desync.
- Client interpolation smooths rendering; server remains authoritative.
- Zone context can be included in updates so client can reflect risk/profit feedback without owning game truth.

## 6) Failure modes

- Redis unavailable: login hydration falls back to Postgres; degraded latency but service remains functional.
- Postgres unavailable: login/profile and durable operations fail; API should return explicit errors.
- WebSocket disconnects: client reconnects and requests fresh snapshot.
- Clock skew / stale sequence: server validates sequence and ignores stale input.
- Data drift between cache and DB: tolerated due to short TTL and deterministic fallback to DB.

## 7) Scaling strategy

MVP scale:
- Single API process + one Postgres + one Redis instance.

Next steps:
- Split realtime simulation loop from HTTP API if load grows.
- Introduce sharding/instances per star system region if needed.
- Use Redis pub/sub or message bus for cross-instance event fanout.
- Add read replicas for Postgres when read pressure increases.
- Add observability (p95 login latency, websocket tick lag, cache hit rate, DB query time) before major scaling changes.

## 8) Why certain tech choices were made

- FastAPI: fast iteration speed, typed contracts, async support.
- PostgreSQL: strong consistency and relational integrity for economy and player progression.
- Redis: low-latency cache for frequent login hydration and hot profile reads.
- Docker Compose: reproducible local environment and easy team onboarding.
- Server-authoritative realtime model: better anti-cheat posture and deterministic simulation behavior.

This document is intentionally short and will evolve with implementation milestones.

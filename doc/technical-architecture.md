# Technical Architecture (Draft)

## High-Level

- **Client:** Web frontend (2D canvas engine), input + rendering.
- **Server:** Python async backend (authoritative simulation loop).
- **Transport:** WebSocket for realtime gameplay, HTTP for account/market UI.
- **Database:** PostgreSQL for persistent player/world data.

## Backend Responsibilities

- Authenticate player sessions against persisted player records.
- Simulate physics/combat on fixed tick rate (e.g. 20–30 TPS).
- Validate player input and prevent cheating.
- Compute NPC behavior and encounters.
- Process trading transactions atomically.
- Broadcast world snapshots/deltas to clients.

Auth persistence notes:
- Registration writes new users to PostgreSQL.
- Login verifies password hash from PostgreSQL (no hard-coded or in-memory credential list).
- Protected HTTP/WebSocket flows resolve token subject to existing `players.id`.

## Suggested Stack

- Python 3.12+
- FastAPI + Uvicorn
- WebSockets via FastAPI
- SQLAlchemy + Alembic
- PostgreSQL
- Redis (optional, for pub/sub, transient state, scaling)

## Realtime Model

- Client sends compact input commands (`thrust`, `turn`, `fire`, `dock_request`).
- Server applies commands next tick.
- Server publishes state updates at fixed interval.
- Client performs interpolation/prediction for smooth visuals.

## Core Domain Entities

- Player
- Ship
- Planet/Station
- Commodity
- MarketPrice
- ZoneRiskProfile
- NPCPirate
- CombatEvent
- Transaction

## Security and Fairness

- Server is source of truth.
- Rate-limit commands.
- Validate impossible movement/fire rate.
- Signed auth tokens for sessions.

## Deployment (Phase 1)

- Monolith API + simulation process.
- One game instance (single shard).
- Containerized deployment.

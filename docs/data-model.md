# Data Model (MVP)

## Purpose

Define persistent entities, fields, and relationships for the StarTrader MVP backend.

## Database

- Engine: PostgreSQL
- Time fields: UTC `timestamptz`
- IDs: UUID (or `text` with prefixed IDs during prototype)

## Core Tables

## `players`

Stores player identity and progression.

| Field | Type | Notes |
|---|---|---|
| id | uuid (pk) | Player ID |
| username | varchar(32) unique | Public name |
| password_hash | text | Auth hash |
| credits | bigint | Current balance |
| reputation | int | Optional MVP soft stat |
| created_at | timestamptz | |
| updated_at | timestamptz | |

Indexes:
- unique(`username`)

## `ships`

One active ship per player for MVP.

| Field | Type | Notes |
|---|---|---|
| id | uuid (pk) | Ship ID |
| player_id | uuid (fk players.id) unique | Owner |
| ship_class | varchar(32) | e.g. `starter_freighter` |
| hull_current | int | Current HP |
| hull_max | int | Max HP |
| fuel_current | int | Current fuel |
| fuel_max | int | Max fuel |
| cargo_capacity | int | Cargo volume slots |
| is_destroyed | boolean | Respawn/insurance flow later |
| created_at | timestamptz | |
| updated_at | timestamptz | |

Indexes:
- unique(`player_id`)

## `locations`

Planets/stations used for docking and market trading.

| Field | Type | Notes |
|---|---|---|
| id | uuid (pk) | Location ID |
| code | varchar(64) unique | e.g. `earth-orbit-station` |
| name | varchar(128) | Display name |
| location_type | varchar(16) | `planet` or `station` |
| x | double precision | 2D map coordinate |
| y | double precision | 2D map coordinate |
| security_level | int | 0..100 influences pirate risk |
| has_market | boolean | Trading available |
| has_repair | boolean | Repair available |
| has_refuel | boolean | Refuel available |
| created_at | timestamptz | |
| updated_at | timestamptz | |

Indexes:
- unique(`code`)

## `commodities`

Tradable goods catalog.

| Field | Type | Notes |
|---|---|---|
| id | uuid (pk) | Commodity ID |
| code | varchar(64) unique | e.g. `food` |
| name | varchar(128) | |
| unit_mass | int | Cargo unit mass/slot multiplier |
| base_price | int | Baseline economy price |
| illegal_level | int | 0 for legal in MVP |
| created_at | timestamptz | |
| updated_at | timestamptz | |

Indexes:
- unique(`code`)

## `market_prices`

Current buy/sell prices per location + commodity.

| Field | Type | Notes |
|---|---|---|
| id | uuid (pk) | |
| location_id | uuid (fk locations.id) | Market location |
| commodity_id | uuid (fk commodities.id) | Good |
| buy_price | int | Player buys from market |
| sell_price | int | Player sells to market |
| stock_qty | int | Optional MVP stock pressure |
| updated_at | timestamptz | Last rebalance |

Constraints:
- unique(`location_id`, `commodity_id`)
- `buy_price >= sell_price`
- `buy_price > 0`, `sell_price > 0`

## `ship_cargo`

Persistent cargo in ship hold.

| Field | Type | Notes |
|---|---|---|
| ship_id | uuid (fk ships.id) | |
| commodity_id | uuid (fk commodities.id) | |
| quantity | int | Non-negative |
| updated_at | timestamptz | |

Constraints:
- primary key(`ship_id`, `commodity_id`)
- `quantity >= 0`

## `ship_state_docked`

Last persistent docked state (runtime combat position stays in memory).

| Field | Type | Notes |
|---|---|---|
| ship_id | uuid (pk, fk ships.id) | |
| location_id | uuid (fk locations.id) | Current docked location |
| docked_at | timestamptz | |
| undocked_at | timestamptz nullable | |

## `zone_profiles`

Persistent spatial risk/reward definitions used by free-flight simulation.

| Field | Type | Notes |
|---|---|---|
| id | uuid (pk) | Zone ID |
| zone_type | varchar(32) | `core_safe`, `approach_high_value`, `belt_open`, `edge_wild` |
| center_x | double precision | 2D center |
| center_y | double precision | 2D center |
| radius | double precision | Zone radius |
| risk_level | int | 0..100 |
| security_level | int | 0..100 |
| profit_multiplier | numeric(4,2) | e.g. `1.00` to `1.60` |
| pvp_allowed | boolean | PvP policy hook |
| active | boolean | Runtime enabled/disabled |
| created_at | timestamptz | |
| updated_at | timestamptz | |

Constraints:
- `radius > 0`
- `risk_level BETWEEN 0 AND 100`
- `security_level BETWEEN 0 AND 100`
- `profit_multiplier >= 1.0`

Indexes:
- index(`zone_type`, `active`)

## `combat_logs`

Auditable combat events (optional lightweight MVP).

| Field | Type | Notes |
|---|---|---|
| id | uuid (pk) | |
| tick | bigint | Server sim tick |
| event_type | varchar(32) | `hit`, `destroyed`, `projectile_fired` |
| source_entity_id | uuid nullable | Player/NPC source |
| target_entity_id | uuid nullable | Player/NPC target |
| damage | int nullable | |
| payload_json | jsonb | Extra event payload |
| created_at | timestamptz | |

Indexes:
- index(`target_entity_id`, `created_at`)
- index(`source_entity_id`, `created_at`)

## `transactions`

Economy transaction ledger for buy/sell/repair/refuel.

| Field | Type | Notes |
|---|---|---|
| id | uuid (pk) | |
| player_id | uuid (fk players.id) | |
| ship_id | uuid (fk ships.id) | |
| location_id | uuid (fk locations.id) | |
| tx_type | varchar(16) | `buy`, `sell`, `repair`, `refuel` |
| commodity_id | uuid nullable (fk commodities.id) | null for repair/refuel |
| quantity | int nullable | |
| unit_price | int | |
| total_amount | int | Signed or positive by type |
| created_at | timestamptz | |

Indexes:
- index(`player_id`, `created_at`)
- index(`location_id`, `created_at`)

## Runtime-Only (Not Persisted in MVP)

Held in simulation process memory, rebuilt from persistent state at session join:

- Active entity transforms (`x`, `y`, `vx`, `vy`, `r`)
- Projectiles
- NPC pirate AI state
- Per-tick cooldowns and command buffers

## Relationship Summary

- `players` 1:1 `ships`
- `ships` 1:N `ship_cargo`
- `locations` 1:N `market_prices`
- `commodities` 1:N `market_prices`
- `players` 1:N `transactions`
- `ships` 1:1 `ship_state_docked` (MVP persistence model)
- `zone_profiles` are read by simulation for per-position risk/reward evaluation

## Protocol Mapping

From [realtime-protocol.md](./realtime-protocol.md):

- `auth.ok.player_id` -> `players.id`
- `session.joined.ship_id` -> `ships.id`
- `world.snapshot.you.credits` -> `players.credits`
- `world.snapshot.you.cargo` -> `ship_cargo`
- `world.snapshot.markets` -> `market_prices`
- `world.snapshot.zones` -> `zone_profiles` (active subset for client awareness)
- `trade.buy` / `trade.sell` -> update `ship_cargo`, `players.credits`, insert `transactions`

## Transaction Rules

For `trade.buy` and `trade.sell`:

1. Verify ship is docked at requested station.
2. Lock player + cargo + market rows (`SELECT ... FOR UPDATE`).
3. Validate credits/cargo capacity/quantity.
4. Apply updates atomically.
5. Insert `transactions` record.
6. Commit and emit `trade.result`.

## Migration Strategy

- Start with tables above in baseline migration.
- Seed initial locations, commodities, and market prices.
- Keep schema MVP-stable; add advanced systems in additive migrations.

# Seed Load Order (MVP)

## Purpose

Define deterministic load order and sanity checks for Sol-1 seed data.

## Files

1. `sol1-locations.yaml`
2. `sol1-commodities.yaml`
3. `sol1-market-prices.yaml`
4. `sol1-zones.yaml`

## Why This Order

- Market prices reference location + commodity IDs, so both catalogs must exist first.
- Zones are independent from market rows, but loaded last to keep gameplay activation explicit after economy bootstrap.

## Recommended Import Process

1. Begin DB transaction.
2. Upsert locations by `id`/`code`.
3. Upsert commodities by `id`/`code`.
4. Upsert market prices by (`location_id`, `commodity_id`).
5. Upsert zones by `id`.
6. Commit transaction.

If any validation fails, rollback all inserts/updates.

## Required Validations

## Locations

- All `id` values unique.
- `security_level` in `[0, 100]`.
- Coordinates inside world bounds (recommended `[-8000, 8000]`).

## Commodities

- All `id` values unique.
- `unit_mass > 0`.
- `base_price > 0`.
- `volatility` in `[0.05, 0.35]` (MVP guideline).

## Market Prices

For each item:
- `location_id` exists in locations table.
- `commodity_id` exists in commodities table.
- `buy_price >= sell_price > 0`.
- `stock_qty >= 0`.

Cross-check:
- Every station should have at least 4 commodities to avoid dead markets.

## Zones

- `zone_type` in allowed enum (`core_safe`, `approach_high_value`, `belt_open`, `edge_wild`).
- `radius > 0`.
- `risk_level` and `security_level` in `[0, 100]`.
- `profit_multiplier >= 1.0`.
- `core_safe` zones should have `pvp_allowed: false`.

## Post-Load Smoke Checks

- Can fetch all 4 locations from API.
- Can fetch market prices for each location.
- At least one ship spawn point falls inside a `core_safe` zone.
- Zone query at Earth/Mars/Jupiter coordinates returns expected zone IDs.

## Idempotency Rules

- Seed scripts must be rerunnable.
- Use upserts (not blind inserts).
- Keep a `version` field in seed files; reject older version if strict mode is enabled.

## Suggested Error Output Format

On validation error, report:

- file name
- record index
- field name
- expected rule
- actual value

Example:

`sol1-market-prices.yaml item[12].buy_price expected >= sell_price, got buy=14 sell=18`

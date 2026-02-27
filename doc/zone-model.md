# Zone Model (Free-Flight)

## Principle

There are no fixed travel routes. Players can fly freely anywhere in the system.

Risk/reward is controlled by spatial zones that affect encounters, profitability, and PvP rules.

## Zone Definition

A zone is a circular area in 2D space:

- `id`
- `zone_type`
- `center_x`, `center_y`
- `radius`
- `risk_level` (0..100)
- `security_level` (0..100)
- `profit_multiplier` (1.0+)
- `pvp_allowed` (bool)
- `active` (bool)

## MVP Zone Types

- `core_safe` — around high-security stations; low pirate chance; no PvP.
- `approach_high_value` — around profitable stations/planets; high pirate chance; optional PvP.
- `belt_open` — transit regions with medium risk/reward.
- `edge_wild` — system edges; high risk and high reward.

## Runtime Evaluation

At every server tick for each ship:

1. Find all active zones containing ship position.
2. Blend zone attributes by proximity.
3. Compute encounter probability and combat policy from blended values.
4. Accumulate per-trip zone exposure for reward/risk analytics.

## Overlap Blending

For zone $i$:

$$
weight_i = max(1 - dist(pos, center_i)/radius_i, 0)
$$

Blended attribute $A$:

$$
A_{blend} = \frac{\sum_i A_i \cdot weight_i}{\sum_i weight_i}
$$

Fallback if no zone contains position:
- Apply default background values (`risk=0.15`, `security=0.35`, `profit=1.0`).

## Approach Zone Generation (MVP)

For each market location, auto-generate one approach zone:

- `radius`: 600–1200 units (based on location importance)
- `risk_level`: proportional to average market spread/profitability
- `security_level`: inverse of risk, except safe capitals
- `profit_multiplier`: 1.1–1.6

This ensures profitable destinations naturally attract danger without forcing paths.

## Anti-Camping Rules

- Spawn-protection ring inside `core_safe` with no hostile fire.
- Pirate spawn minimum distance from station docks.
- Pirate despawn/retarget if players stay inside inner safe radius.

## Telemetry

Track by zone type:

- Time spent
- Encounter count
- Death count
- Net credits change
- Average cargo value entering zone

These metrics tune risk and profit multipliers over time.

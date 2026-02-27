# Sol-1 Zone Seed (MVP)

## Purpose

Provide concrete, first-pass zone values for the single-system MVP so backend and gameplay tuning start from the same map.

## Coordinate Space

- 2D plane in arbitrary world units.
- System center: `(0, 0)`.
- Suggested playable bounds: `x, y in [-8000, 8000]`.

## Key Locations (Reference)

- Earth Orbit Station: `(-1200, 300)`
- Mars Orbit Station: `(2200, -600)`
- Ceres Hub: `(800, 2100)`
- Jupiter Trade Ring: `(5400, 1200)`

## Zones (Initial)

### Core Safe

1) `z_earth_core_safe`
- center: `(-1200, 300)`
- radius: `550`
- risk_level: `8`
- security_level: `92`
- profit_multiplier: `1.00`
- pvp_allowed: `false`

2) `z_mars_core_safe`
- center: `(2200, -600)`
- radius: `500`
- risk_level: `10`
- security_level: `88`
- profit_multiplier: `1.00`
- pvp_allowed: `false`

### High-Value Approaches

3) `z_earth_approach_high_value`
- center: `(-1200, 300)`
- radius: `1250`
- risk_level: `58`
- security_level: `42`
- profit_multiplier: `1.22`
- pvp_allowed: `true`

4) `z_mars_approach_high_value`
- center: `(2200, -600)`
- radius: `1350`
- risk_level: `66`
- security_level: `34`
- profit_multiplier: `1.28`
- pvp_allowed: `true`

5) `z_jupiter_approach_high_value`
- center: `(5400, 1200)`
- radius: `1700`
- risk_level: `78`
- security_level: `22`
- profit_multiplier: `1.45`
- pvp_allowed: `true`

### Belt/Open Transit

6) `z_inner_belt_open`
- center: `(700, 500)`
- radius: `2500`
- risk_level: `38`
- security_level: `52`
- profit_multiplier: `1.10`
- pvp_allowed: `true`

7) `z_ceres_belt_open`
- center: `(800, 2100)`
- radius: `1600`
- risk_level: `44`
- security_level: `46`
- profit_multiplier: `1.16`
- pvp_allowed: `true`

### Edge Wild

8) `z_outer_edge_wild_east`
- center: `(6900, 400)`
- radius: `1900`
- risk_level: `90`
- security_level: `10`
- profit_multiplier: `1.58`
- pvp_allowed: `true`

9) `z_outer_edge_wild_northwest`
- center: `(-5400, 5200)`
- radius: `1800`
- risk_level: `86`
- security_level: `12`
- profit_multiplier: `1.52`
- pvp_allowed: `true`

## Expected Experience

- New players can stay mostly in Earth/Mars core-safe + inner belt and survive.
- Profit seekers can run Mars and Jupiter approaches for stronger margins with higher pirate pressure.
- Edge zones are optional high-risk areas for advanced or group play.

## Spawn and Safety Rules

- Player spawn point stays inside `z_earth_core_safe`.
- Hostile fire disabled in all `core_safe` zones.
- Pirate spawns prohibited inside core-safe radius and within `250` units outside core-safe edge.

## Recommended First Tuning Pass

If deaths are too high in first sessions:
- reduce approach zone `risk_level` by `8–12`
- increase approach `security_level` by `6–10`

If economy is too safe/flat:
- increase Jupiter approach `profit_multiplier` to `1.50`
- slightly increase belt/open `risk_level` by `4–6`

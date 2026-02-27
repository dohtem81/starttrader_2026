# Balance Rules (MVP)

## Purpose

Define simple, tunable rules for economy, travel risk, and combat so the first playable build feels fair and testable.

## Design Targets

- A profitable trade run should take 4–8 minutes.
- Safe zones should be low profit, low danger.
- Risky zones should offer 1.5x–2.5x expected profit.
- Average time-to-kill (TTK) in equal ship duel: 12–20 seconds.
- New players should survive at least one pirate encounter if they disengage early.

## Economy

## Commodity Baseline

Each commodity has:
- `base_price`
- `volatility` in range `[0.05, 0.35]`
- `mass`

### Price Formula

At location $l$ for commodity $c$:

$$
mid_c = base_c \cdot (1 + local_bias_{l,c})
$$

$$
spread_c = 0.08 + 0.12 \cdot volatility_c
$$

$$
buy_{l,c} = round(mid_c \cdot (1 + spread_c/2 + demand_shift_{l,c}))
$$

$$
sell_{l,c} = round(mid_c \cdot (1 - spread_c/2 + supply_shift_{l,c}))
$$

Constraints:
- `buy >= sell`
- `buy > 0`, `sell > 0`
- Clamp total modifier to `[-0.45, +0.80]`

### Update Cadence

- Recompute market every 60 seconds.
- Apply small random drift per tick window: ±1–3% capped.
- Apply trade impact:
  - Player buys from station: short-term `buy` increases.
  - Player sells to station: short-term `sell` decreases.

### Trade Profit Guardrails

For an origin/destination pair and cargo plan:

$$
expected\_margin = revenue - cost - fuel\_cost - repair\_risk\_cost
$$

Target:
- Safe approaches: `expected_margin / cost` around 5–12%
- Medium-risk space: 10–20%
- High-risk approaches: 18–35%

## Zone Risk + Pirate Spawns

Flight is fully free. Risk is derived from the ship's current position and nearby zone overlays, not from predefined routes.

Each zone has:
- `zone_type`
- `center_x`, `center_y`, `radius`
- `risk_level` (0–100)
- `security_level` (0–100, higher is safer)
- `profit_multiplier` (e.g. 1.0 to 1.6)

### Zone Types (MVP)

- `core_safe`: around spawn/high-security stations, very low pirate activity
- `approach_high_value`: around profitable planets/stations, elevated pirate activity
- `belt_open`: medium danger, medium reward transit space
- `edge_wild`: high danger perimeter areas

### Encounter Chance per Minute

$$
p = clamp(0.01 + 0.22 \cdot risk + 0.08 \cdot cargo + 0.06 \cdot heat - 0.10 \cdot security,\ 0.01,\ 0.45)
$$

Where:
- `risk` = zone risk level normalized to `[0,1]`
- `cargo` = current cargo fill ratio `[0,1]`
- `heat` = recent combat/aggression score `[0,1]`
- `security` = zone security normalized to `[0,1]`

Interpretation:
- Core safe zones: ~1–4%/min
- Open/belt zones: ~8–18%/min
- High-value approach/edge zones: ~20–45%/min

### Zone Blending (Overlaps)

If multiple zones overlap current position, use weighted blend by distance to center:

$$
weight_i = 1 - \frac{dist(pos, center_i)}{radius_i}
$$

$$
risk_{blended} = \frac{\sum_i risk_i \cdot max(weight_i, 0)}{\sum_i max(weight_i, 0)}
$$

Use the same method for blended security/profit multipliers.

### Profit by Zone Exposure

Each trip gets an exposure score from time spent in higher-profit zones:

$$
trip\_profit\_multiplier = 1 + clamp(\sum zone\_time\_fraction \cdot (profit\_multiplier - 1),\ 0,\ 0.6)
$$

This rewards deliberate risky approaches while preserving free-flight choice.

### Pirate Strength Scaling

Pirate ship tier from player net worth:

$$
net\_worth = credits + ship\_value + cargo\_value
$$

- Tier 1 if net worth < 20k
- Tier 2 if 20k–80k
- Tier 3 if > 80k

Spawn 1–3 pirates based on current blended zone danger and nearby player group size.

## Combat Defaults (Starter Pass)

## Starter Freighter

- Hull: 100
- Shield: 0 (MVP), optional later
- Max speed: 120 units/s
- Turn rate: 2.2 rad/s
- Cargo capacity: 30

## Pirate Raider (Tier 1)

- Hull: 80
- Max speed: 135 units/s
- Turn rate: 2.5 rad/s
- Weapon cooldown: 0.45 s
- Projectile damage: 8

## Player Basic Cannon

- Cooldown: 0.40 s
- Projectile speed: 280 units/s
- Damage: 10
- Lifetime: 1.6 s

### DPS Reference

$$
DPS = damage / cooldown
$$

- Player cannon DPS: $10/0.40 = 25$
- Pirate raider DPS: $8/0.45 \approx 17.8$

This gives new players a fair duel edge but pirates gain pressure via numbers/positioning.

## Repair + Fuel Costs

- Repair cost per missing hull point: `2 credits`
- Refuel cost per fuel unit: `1 credit`
- Emergency tow/respawn fee (if destroyed): `8%` of current credits, min `200`

## PvP (MVP Optional Toggle)

If PvP enabled:
- Allow damage only in designated risk zones.
- Apply destruction penalty cap: max `15%` cargo value loss.
- Add short undock protection: `8 seconds`.

## Anti-Exploit Constraints

- Server clamps input and fire rate.
- No market action unless docked.
- Minimum price floors to avoid zero/negative loops.
- Cooldown on repeated buy/sell same commodity at same station (e.g., 1–2 seconds).

## Telemetry to Track

Track per day/session:
- Average credits/hour
- Median run profit by origin/destination and zone exposure
- Death causes (% pirates, % PvP, % collision)
- Encounter rate by zone type
- Market spread utilization (are players using many goods or only one)

## Tuning Workflow

1. Run closed test with 10–30 players.
2. Compare actuals to design targets.
3. Adjust only 2–3 knobs per patch (e.g., pirate chance, spread, repair cost).
4. Re-test for 24–48h before next balance patch.

## Initial Tunable Config Block

```yaml
economy:
  market_update_seconds: 60
  spread_base: 0.08
  spread_volatility_factor: 0.12
  drift_percent_min: -0.03
  drift_percent_max: 0.03

risk:
  encounter_base: 0.01
  encounter_risk_factor: 0.22
  encounter_cargo_factor: 0.08
  encounter_heat_factor: 0.06
  encounter_security_factor: 0.10
  encounter_min: 0.01
  encounter_max: 0.45

combat:
  player_cannon_damage: 10
  player_cannon_cooldown: 0.40
  pirate_t1_damage: 8
  pirate_t1_cooldown: 0.45

costs:
  repair_per_hull: 2
  refuel_per_unit: 1
  respawn_credit_loss_percent: 0.08
  respawn_credit_loss_min: 200
```

## Notes

- Keep numbers intentionally simple for MVP.
- Prefer predictable economy over realism at this stage.
- Revisit all constants after first telemetry batch.
- Keep free flight unrestricted; zones only influence risk/reward, never hard-path movement.

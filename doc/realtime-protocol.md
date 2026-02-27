# Realtime Protocol (WebSocket)

## Purpose

Define a minimal, stable message contract between web client and Python game server for MVP realtime gameplay.

## Transport

- Protocol: WebSocket over TLS (`wss://` in production)
- Encoding: JSON (MVP), optional binary later
- Tick target: 20–30 server ticks per second

## Envelope

All messages share this envelope shape:

```json
{
  "type": "message_type",
  "seq": 123,
  "ts": 1700000000000,
  "payload": {}
}
```

Fields:
- `type`: Message identifier.
- `seq`: Client or server sequence number for ordering/ack.
- `ts`: Unix epoch milliseconds.
- `payload`: Type-specific body.

## Connection Flow

1. Client opens WebSocket.
2. Client sends `auth.login`.
3. Server responds `auth.ok` (or `auth.error`).
4. Client sends `session.join_system`.
5. Server sends `session.joined` and starts state streaming.

## Client -> Server Messages

### auth.login

```json
{
  "type": "auth.login",
  "seq": 1,
  "ts": 1700000000000,
  "payload": {
    "token": "jwt_or_session_token"
  }
}
```

### session.join_system

```json
{
  "type": "session.join_system",
  "seq": 2,
  "ts": 1700000000100,
  "payload": {
    "system_id": "sol-1"
  }
}
```

### input.command

High frequency, compact player input.

```json
{
  "type": "input.command",
  "seq": 40,
  "ts": 1700000000500,
  "payload": {
    "thrust": 0.8,
    "turn": -0.4,
    "fire_primary": true,
    "dock_request": false
  }
}
```

Constraints:
- `thrust`: float in `[0, 1]`
- `turn`: float in `[-1, 1]`
- `fire_primary`: boolean
- `dock_request`: boolean

### trade.buy

```json
{
  "type": "trade.buy",
  "seq": 55,
  "ts": 1700000001000,
  "payload": {
    "station_id": "earth-orbit-station",
    "commodity_id": "food",
    "quantity": 10
  }
}
```

### trade.sell

```json
{
  "type": "trade.sell",
  "seq": 56,
  "ts": 1700000001200,
  "payload": {
    "station_id": "mars-orbit-station",
    "commodity_id": "food",
    "quantity": 10
  }
}
```

### ship.repair_request

```json
{
  "type": "ship.repair_request",
  "seq": 60,
  "ts": 1700000001300,
  "payload": {
    "station_id": "mars-orbit-station"
  }
}
```

## Server -> Client Messages

### auth.ok / auth.error

```json
{
  "type": "auth.ok",
  "seq": 1,
  "ts": 1700000000010,
  "payload": {
    "player_id": "p_123"
  }
}
```

```json
{
  "type": "auth.error",
  "seq": 1,
  "ts": 1700000000010,
  "payload": {
    "code": "INVALID_TOKEN",
    "message": "Authentication failed"
  }
}
```

### session.joined

```json
{
  "type": "session.joined",
  "seq": 2,
  "ts": 1700000000200,
  "payload": {
    "system_id": "sol-1",
    "ship_id": "s_987",
    "spawn": { "x": 1200, "y": 400, "rotation": 1.57 }
  }
}
```

### world.snapshot

Sent on join and occasionally for correction.

```json
{
  "type": "world.snapshot",
  "seq": 100,
  "ts": 1700000000500,
  "payload": {
    "tick": 5010,
    "you": {
      "ship_id": "s_987",
      "credits": 5000,
      "hull": 100,
      "fuel": 100,
      "cargo": [{ "commodity_id": "food", "qty": 10 }]
    },
    "entities": [
      { "id": "s_987", "kind": "player_ship", "x": 1200, "y": 400, "vx": 0, "vy": 0, "r": 1.57, "hp": 100 },
      { "id": "npc_1", "kind": "pirate", "x": 1400, "y": 450, "vx": -10, "vy": 3, "r": 3.1, "hp": 80 }
    ],
    "markets": [
      {
        "station_id": "earth-orbit-station",
        "prices": [{ "commodity_id": "food", "buy": 11, "sell": 9 }]
      }
    ],
    "zones": [
      {
        "zone_id": "z_earth_approach",
        "zone_type": "approach_high_value",
        "center": { "x": 1200, "y": 400 },
        "radius": 900,
        "risk_level": 72,
        "security_level": 35,
        "profit_multiplier": 1.35,
        "pvp_allowed": true
      }
    ]
  }
}
```

### world.delta

High-frequency update message.

```json
{
  "type": "world.delta",
  "seq": 101,
  "ts": 1700000000550,
  "payload": {
    "tick": 5011,
    "entity_updates": [
      { "id": "s_987", "x": 1201, "y": 401, "vx": 8, "vy": 2, "r": 1.62, "hp": 100 }
    ],
    "entity_removed": [],
    "events": [
      { "kind": "projectile_fired", "source_id": "npc_1", "projectile_id": "pr_22" }
    ],
    "you_zone_context": {
      "zone_ids": ["z_earth_approach"],
      "blended_risk": 0.68,
      "blended_security": 0.32,
      "blended_profit_multiplier": 1.28
    }
  }
}
```

### trade.result

```json
{
  "type": "trade.result",
  "seq": 57,
  "ts": 1700000001210,
  "payload": {
    "ok": true,
    "credits": 6120,
    "cargo": [{ "commodity_id": "food", "qty": 0 }],
    "details": {
      "station_id": "mars-orbit-station",
      "commodity_id": "food",
      "quantity": 10,
      "unit_price": 15,
      "total": 150
    }
  }
}
```

### combat.event

```json
{
  "type": "combat.event",
  "seq": 120,
  "ts": 1700000000800,
  "payload": {
    "kind": "hit",
    "source_id": "npc_1",
    "target_id": "s_987",
    "damage": 12,
    "target_hp": 88
  }
}
```

### error

```json
{
  "type": "error",
  "seq": 58,
  "ts": 1700000001220,
  "payload": {
    "code": "NOT_DOCKED",
    "message": "Trading requires docking"
  }
}
```

## Validation Rules (Server-side)

- Ignore or reject stale `seq` values.
- Clamp out-of-range input values.
- Reject trade/repair unless ship is docked and at valid station.
- Enforce cooldowns for firing and action spam.
- Never trust client position/hp/cargo.

## Reliability Strategy

- Realtime state is best-effort (`world.delta`).
- Periodic `world.snapshot` corrects drift.
- Important transactional replies (`trade.result`) are explicit and final.

## Versioning

- Include protocol version in connect params or first auth payload.
- Example: `"protocol_version": 1`.
- Increment only on breaking changes.

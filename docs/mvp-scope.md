# MVP Scope

## MVP Goal

Deliver a playable multiplayer prototype where players can:

1. Spawn at a station.
2. Buy cargo.
3. Fly to another planet/station in realtime.
4. Encounter pirates.
5. Fight or flee.
6. Dock and sell cargo.
7. Earn/loss credits persistently.

## Included in MVP

### Gameplay

- 2D top-down ship movement (thrust, rotation).
- Basic ship stats: hull, cargo, speed, shield (optional v1.1).
- Commodity trading on at least 4 locations.
- Pirate NPC spawns based on dynamic space zones (especially approach zones near profitable locations).
- Basic weapons (projectile) and damage model.
- Repair and refuel at stations.

### Multiplayer

- Multiple concurrent players in one shared system instance.
- Realtime state sync via WebSockets.
- Server-authoritative movement/combat.

### Economy

- Credits, cargo hold capacity, and item quantities.
- Location-based buy/sell prices.
- Price variance over time (simple periodic or event-driven adjustment).

### Persistence

- Player account/profile.
- Ship state (position at dock, hp, fuel).
- Inventory/cargo and credits.

## Excluded for MVP (Later)

- Multiple star systems.
- Guilds/fleets.
- Complex manufacturing chains.
- Advanced ship fitting with many modules.
- Territory control.
- Mobile client.

## Implemented (v2.0.0)

- [x] In-game checklist tracking all 12 entries across 2 categories (6 Cyberware Capacity Shards + 6 shardless Cyberjunkies).
- [x] 0-Engine proximity scanner: event-driven (no polling interval), notifies within `scanner_radius` (default 50m, adjustable 25-100m). No CPU cost when away.
- [x] Kill-fact detection of defeated Cyberjunkies; shard Cyberjunkies additionally verify the looted shard before checking off.
- [x] Spawn-fact gating + prerequisite display for gated Cyberjunkies (e.g. "Defeat any 4 Cyberjunkies").
- [x] CW Capacity Shard loot detection via inventory observer + closest-uncollected resolve.
- [x] NPC-following detection markers for Cyberjunkies (static marker for the Stadium cache).
- [x] Smart Pause: scanner suppressed during loading screens, fast travel, and menus.
- [x] Survives saves/autosaves (no PlayerInvalidated teardown).
- [x] Set Pin waypoint (standalone manual map waypoint, decoupled from Core).
- [x] Teleport to any uncollected entry (Lazy Mode); Unstuck.
- [x] Per-character save persistence.

## Planned

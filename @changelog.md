### [2026-05-19] v2.0.0 — 0-Engine migration

- **[Major] Proximity backend migrated from Cron polling to 0-Engine reactive primitives** (SpatialSet + per-entry detection zones). Removed `Cron.lua`, the polling loop, and the `scanner_interval` config. `init.lua` rewritten: `GetMod` inside `onInit`, `Mod.WhenReady` priority 2, `GameSession.OnEnd` for `isSessionActive` gating. `Automation.lua` is a thin wrapper over the shared `ChecklistCore` (byte-identical across all 4 mods).
- **[New] Required dependency**: 0-Engine (Nexus 27967, pure CET-only build, 0.18.3+). 0-Engine itself requires CET 1.32+, Codeware 1.12+, redscript 0.5.19+.
- **[New] NPC-following detection mappins for Cyberjunkies.** Cyberjunkie entries use the Core `attachToEntity` config: the detection mappin is registered against the resolved NPC entity (`RegisterMappinWithObject`) and re-attaches on the snap-zone `onTick` so it tracks the moving target instead of a static point. Cache entries (Stadium Parking) keep the static `SetMappinPosition` path. (Wiki: `concepts/0-engine-integration-pattern`.)
- **[Change] All 6 category-2 Cyberjunkie `container_id`s populated in `db.lua`.** Previously `nil` (they drop no shard); set anyway so entity-attach detection resolves the NPC body for every Cyberjunkie. Confirmed safe in-game (no false collects).
- **[Change] No `PlayerInvalidated` teardown subscriber.** 0-Engine's `Reset()` does not unregister sets/zones; subscribing a teardown there converts a transient false-invalidation into permanent breakage. Registrations persist; 0-Engine auto-resumes on Lifecycle recovery. This also fixed the Stadium-cache post-teleport false-collect. (Wiki: `learnings/0-engine-playerinvalidated-no-teardown`.)
- **[Change] "Set Pin" decoupled** into a standalone `init.lua` manual waypoint, independent of Core. Net user-facing behaviour unchanged. (Wiki: `decisions/user-pin-decoupled-from-core`.)
- **[New] `GameUI.lua`** (psiberx CET Kit) added for fast loading-screen detection.
- **[Note] Versioning.** The public Nexus 1.0.0 already shipped all 12 entries, Cyberjunkie tracking, kill-fact detection, and spawn-requirement gating. The internal v1.1.0 (Cyberjunkie Expansion) and v1.2.0 (Kill Fact Automation Refactor) entries below were local dev iteration labels bundled into that same public 1.0.0; they were never separate Nexus uploads. The only user-facing deltas in public 2.0.0 are the 0-Engine items above (new dependency, rebuilt scanner, NPC-following markers, removed scanner interval).

### [2026-02-25] v1.2.0 Kill Fact Automation Refactor

- **[CCSC] Automation.lua v1.2.0**:
  - [Breaking] Replaced `CheckQuestFacts()` and `CheckConversationShards()` with unified `CheckKillFacts()`.
  - [New] `kill_fact` is now the primary detection method for all Cyberjunkies.
  - [New] CW Shard Cyberjunkies require both `kill_fact = 1` AND `conversation_shard` in journal.
  - [New] Non-shard Cyberjunkies auto-collect on `kill_fact = 1` alone.
  - [New] `_CheckShardsForEntries()` helper for targeted shard verification.
  - [Change] `CheckProximityTarget()` now skips inventory checks for Cyberjunkies entirely.
  - [Change] Notification label uses `kill_fact` presence instead of `conversation_shard`.
  - [New] `spawn_fact` gating prevents detection of unspawned Cyberjunkies.
  - [New] `TakeDownVariant` mappin for Cyberjunkies, `ServicePointNetTrainerVariant` for caches.
- **[CCSC] init.lua v1.2.0**:
  - [Change] Session start calls `CheckKillFacts()` instead of `CheckConversationShards()`.
  - [Remove] Removed standalone shard-loot trigger (`Onscreen`/`Shard` scan).
- **[CCSC] db.lua v1.2.0**:
  - [New] Added `spawn_fact` and `kill_fact` fields to all Cyberjunkie entries.
  - [Change] Category 2 tracked via `kill_fact` instead of conversation shards.

### [2026-02-24] v1.1.0 Cyberjunkie Expansion

- **[CCSC] db.lua v1.1.0**:
  - [New] Added new "Cyberjunkies" category with 6 entries (Maggie Isley, Cody Crosby, David Dover, Chester Hamilton, Sean McMillan, Greg Wilson).
  - [New] Added `conversation_shard` field to all 11 Cyberjunkie entries for shard-based defeat detection.
- **[CCSC] Automation.lua v1.1.0**:
  - [New] Added `CheckConversationShards()` using `CodexUtils.GetShardsDataArray()` API to detect defeated Cyberjunkies via "Archived Conversation" shards.
  - [Fix] Proximity notification now shows "Cyberjunkie" vs "Shard" based on entry type.
- **[CCSC] init.lua v1.1.0**:
  - [New] Loot observer now triggers conversation shard scan on any shard pickup.
  - [New] Session start runs retroactive shard scan for pre-defeated Cyberjunkies.
- **[CCSC] Utils.lua v1.1.0**:
  - [Fix] Changed `IconGlyphs.ChipVertical` (nil) to `IconGlyphs.Chip` to fix initialization crash.

### [2026-02-24] v1.0.0 Initial

- **[CCSC] Initial mod creation**:
  - [New] Created mod structure based on Perk Shard Checklist architecture.
  - [New] Database with 6 Dogtown Cyberware Capacity Shard entries.
  - [New] Manual checklist mode with interactive UI.
  - [New] Proximity scanner with mappin support.
  - [New] Loot detection via inventory observer (CWCapacityPermaReward filter).
  - [New] Predictive loot resolution for closest uncollected shard.
  - [New] Session persistence per save file.

---

## Historical Changelog (Pre-Restructure)

### v1.0.0
- Initial Upload

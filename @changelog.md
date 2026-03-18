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

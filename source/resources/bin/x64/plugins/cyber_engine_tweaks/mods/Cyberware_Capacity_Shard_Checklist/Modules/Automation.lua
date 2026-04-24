-- ======================================================================================
-- Mod Name: Cyberware Capacity Shard Checklist
-- Author: Spuddeh
-- Description: CCSC-specific automation logic. Delegates shared behaviour to ChecklistCore.
-- Mod Version: 1.1.0
-- ======================================================================================

local Automation        = {}
local Core              = require("Modules/ChecklistCore")
local CyberwareCapacityDB = require("db")
local Utils             = require("Modules/Utils")

-- ### FORWARDED CORE API ###

Automation.SetInCombat              = Core.SetInCombat
Automation.SetInCutscene            = Core.SetInCutscene
Automation.SetMenuPaused            = Core.SetMenuPaused
Automation.SetItemStatus            = Core.SetItemStatus
Automation.HasNearbyEntries         = Core.HasNearbyEntries
Automation.UpdateState              = Core.UpdateState
Automation.RegisterItemSet          = Core.RegisterItemSet
Automation.UnregisterItemSet        = Core.UnregisterItemSet
Automation.RemoveMappin             = Core.RemoveMappin
Automation.ResolveClosestUncollected = Core.ResolveClosestUncollected

-- ### CCSC-SPECIFIC: COLLECTED STATE ###

local _sessionState = nil
local _isDebug      = false

local function IsCollected(id)
    return _sessionState and _sessionState.progress and _sessionState.progress[id] == true
end

-- ### CCSC-SPECIFIC: BUILD ENTRIES ###
-- Both CW Shard caches and Cyberjunkies go into the same SpatialSet.
-- spawn_fact gating is handled in canShow so the entry stays in the SpatialSet
-- and becomes visible once the Cyberjunkie spawns, without a full rebuild.

local function BuildEntries()
    local entries = {}
    for _, cat in ipairs(CyberwareCapacityDB) do
        for _, entry in ipairs(cat.entries) do
            if not IsCollected(entry.id) and entry.coords then
                table.insert(entries, {
                    x       = entry.coords.x,
                    y       = entry.coords.y,
                    z       = entry.coords.z,
                    id      = entry.id,
                    name    = entry.name,
                    dbEntry = entry,
                })
            end
        end
    end
    return entries
end

-- ### CCSC-SPECIFIC: canShow ###
-- Gates mappin + snap zone + notification for Cyberjunkies that haven't spawned yet.

local function CanShow(entry)
    if entry.spawn_fact then
        local qs = Game.GetQuestsSystem()
        return qs ~= nil and qs:GetFactStr(entry.spawn_fact) > 0
    end
    return true
end

-- ### CCSC-SPECIFIC: getMappinVariant ###
-- Cyberjunkies use TakeDownVariant; CW Shard caches use the book icon.

local function GetMappinVariant(entry)
    if entry.kill_fact then
        return gamedataMappinVariant.TakeDownVariant
    end
    return gamedataMappinVariant.ServicePointNetTrainerVariant
end

-- ### CCSC-SPECIFIC: INVENTORY CHECK ###
-- Only the tracked shard counts — other loot in the container doesn't block auto-collect.

local _cwShardKeys = nil
local function CWShardKeys()
    if not _cwShardKeys then
        _cwShardKeys = Core.MakeKeyLookup({
            "Items.CWCapacityPermaReward_Epic",
            "Items.CWCapacityPermaReward_Legendary",
            "Items.CWCapacityPermaReward_Rare",
            "Items.CWCapacityPermaReward_Uncommon",
            "Items.CWCapacityPermaReward_2_Epic",
            "Items.CWCapacityPermaReward_2_Legendary",
            "Items.CWCapacityPermaReward_2_Rare",
            "Items.CWCapacityPermaReward_2_Uncommon",
        })
    end
    return _cwShardKeys
end

local function HasAnyCWCapacityShard(entity)
    return Core.ContainerContainsAny(entity, CWShardKeys())
end

-- ### CCSC-SPECIFIC: onItemEnter ###
-- Notification only. Detection zone handles entity snap + inventory check for caches.
-- Cyberjunkies: kill facts + conversation shards handle detection.

local function OnItemEnter(spatialEntry, _)
    local entry = spatialEntry.dbEntry
    if not Core.IsNotified(entry.id) then
        local label = entry.kill_fact and "Cyberjunkie" or "CW Capacity Shard"
        local displayName = string.gsub(entry.name, "^Cyberjunkie %- ", "")
        Utils.Notify(label .. " detected: " .. displayName)
        Core.SetNotified(entry.id)
    end
end

-- ### CCSC-SPECIFIC: KILL FACT DETECTION ###

-- HELPER: Confirm shard looted via journal conversation shards
-- Returns number of entries confirmed
function Automation._CheckShardsForEntries(entries)
    if #entries == 0 then return 0 end

    local jm = Game.GetJournalManager()
    if not jm then
        if _isDebug then Utils.Log("[ShardScan] JournalManager not available.", Utils.LogLevel.Debug) end
        return 0
    end

    local success, shardData = pcall(function()
        return CodexUtils.GetShardsDataArray(jm, CodexListSyncData.new())
    end)

    if not success or not shardData then
        if _isDebug then
            Utils.Log("[ShardScan] CodexUtils.GetShardsDataArray() failed.", Utils.LogLevel.Debug)
        end
        return 0
    end

    local count = 0
    for _, shard in ipairs(shardData) do
        if shard.data and not shard.isHeader then
            local titleKey = shard.data.title
            if titleKey then
                local localizedTitle = GetLocalizedText(titleKey)
                if localizedTitle and string.find(localizedTitle, "Archived Conversation") then
                    for _, entry in ipairs(entries) do
                        if not IsCollected(entry.id) and
                            string.find(localizedTitle, entry.conversation_shard, 1, true) then
                            Utils.Log("[ShardScan] Kill confirmed + shard matched: " .. entry.id)
                            Core.SetItemStatus(entry.id, true)
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    return count
end

function Automation.CheckKillFacts()
    local qs = Game.GetQuestsSystem()
    if not qs then return end

    local count = 0
    local needsShardCheck = {}

    for _, cat in ipairs(CyberwareCapacityDB) do
        for _, entry in ipairs(cat.entries) do
            if IsCollected(entry.id) then goto continue end

            if entry.quest_fact then
                if qs:GetFactStr(entry.quest_fact) > 0 then
                    Utils.Log("[KillFacts] Quest fact completed: " .. entry.id)
                    Core.SetItemStatus(entry.id, true)
                    count = count + 1
                    goto continue
                end
            end

            if entry.kill_fact then
                if qs:GetFactStr(entry.kill_fact) > 0 then
                    if entry.conversation_shard then
                        table.insert(needsShardCheck, entry)
                    else
                        Utils.Log("[KillFacts] Cyberjunkie defeated: " .. entry.id)
                        Core.SetItemStatus(entry.id, true)
                        count = count + 1
                    end
                end
            end

            ::continue::
        end
    end

    if #needsShardCheck > 0 then
        count = count + Automation._CheckShardsForEntries(needsShardCheck)
    end

    if count > 0 then
        Utils.Log("Retroactively marked " .. count .. " entries via kill facts / shards.")
    elseif _isDebug then
        Utils.Log("[KillFacts] Scan complete. No new matches.", Utils.LogLevel.Debug)
    end
end

-- ### SCAN (overlay open + WhenReady) ###

function Automation.Scan()
    Automation.CheckKillFacts()
    Core.Scan()
end

-- ### INIT ###

function Automation.Init(sessionState, _, debugMode, settings)
    _sessionState = sessionState
    _isDebug      = debugMode or false

    Core.Init(GetMod("0-Engine"), sessionState, settings, {
        setName          = "ccsc_items",
        mappinVariant    = gamedataMappinVariant.ServicePointNetTrainerVariant,
        getMappinVariant = GetMappinVariant,
        snapRadius       = 20.0,
        buildEntries     = BuildEntries,
        canShow          = CanShow,
        onItemEnter      = OnItemEnter,
        onAutoCollect    = function(entry)
            Core.QueueOrShow("CW Capacity Shard already looted: " .. entry.name)
        end,
        -- Inventory check for CW Shard caches only; cyberjunkies use kill_fact detection
        checkInventory   = function(entry, entity)
            if entry.kill_fact then return nil end
            return HasAnyCWCapacityShard(entity)
        end,
        isCollected      = IsCollected,
    }, _isDebug)

    local _, count, total = Core.CheckAllCollected()
    Utils.Log(string.format("Automation Init: %d/%d collected.", count, total))
end

return Automation

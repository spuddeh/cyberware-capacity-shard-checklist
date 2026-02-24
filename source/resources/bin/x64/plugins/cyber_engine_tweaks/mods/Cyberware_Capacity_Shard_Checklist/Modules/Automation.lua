-- ======================================================================================
-- Mod Name: Cyberware Capacity Shard Checklist
-- Author: Spuddeh
-- Description: Handles Proximity Scanning, Mappins, and Auto-Collection Logic.
-- Mod Version: 1.0.0
-- ======================================================================================

local Automation = {}
local CyberwareCapacityDB = require("db")
local Utils = require("Modules/Utils")
local Cron = require("Modules/Cron")
local GameSession = require("Modules/GameSession")
local Ref = require("Modules/Ref")

local _sessionState = nil
local _callbacks = nil
local _isDebug = false
local _settings = nil
local _cronTimerId = nil
local _lastScanTime = 0
local _wasPaused = true
local _unpauseTime = 0

-- ### NOTIFICATION CACHE ###
local _notified_cache = {}

function Automation.ResetNotificationCache()
    if _isDebug then Utils.Log("Resetting Notification Cache.", Utils.LogLevel.Debug) end
    _notified_cache = {}
end

function Automation.OnTeleport()
    -- Set unpause time to future (Current + 7s Cooldown)
    -- This forces ProximityScan to wait, covering the loading screen + loot generation time.
    _unpauseTime = os.clock() + 7.0
    Utils.Log("Teleport detected. Pausing scanner for 7s safety cooldown.")
end

function Automation.SetTimerID(id)
    _cronTimerId = id
end

-- ### STATE HELPERS ###

local function IsCollected(id)
    if _sessionState and _sessionState.progress then
        return _sessionState.progress[id] == true
    end
    return false
end

local function StopScanner()
    if _cronTimerId then
        Cron.Halt(_cronTimerId)
        _cronTimerId = nil
        Utils.Log("All items collected. Stopping Passive Scanner.")
    else
        if _isDebug then Utils.Log("StopScanner called, but scanner was not running.", Utils.LogLevel.Debug) end
    end
end

-- Check if all items in DB are collected (Returns: bool, collectedCount, totalCount)
local function CheckAllCollected()
    local total = 0
    local collected = 0

    for _, cat in ipairs(CyberwareCapacityDB) do
        for _, entry in ipairs(cat.entries) do
            total = total + 1
            if IsCollected(entry.id) then
                collected = collected + 1
            end
        end
    end

    if collected >= total and total > 0 then
        return true, collected, total
    end
    return false, collected, total
end

function Automation.SetItemStatus(id, collected)
    if not _sessionState or not _sessionState.progress then
        if _isDebug then Utils.Log("[SetItemStatus] Error: _sessionState is nil/invalid!", Utils.LogLevel.Error) end
        return
    end

    if _sessionState and _sessionState.progress then
        _sessionState.progress[id] = collected

        local isComplete, count, total = CheckAllCollected()

        if _isDebug then
            Utils.Log(string.format("[SetItemStatus] Item: %s | Status: %s | Progress: %d/%d | Complete: %s",
                id, tostring(collected), count, total, tostring(isComplete)), Utils.LogLevel.Debug)
        end

        -- Optimization: Stop scanner if we just finished the collection
        if collected and isComplete then
            StopScanner()
        end
    end
end

-- HELPER: Robust Inventory Check for CW Capacity Shards
-- Returns: true (Found), false (LoadedButMissing), or nil (NotLoaded/Error)
local function HasAnyCWCapacityShard(entity, trans)
    if not entity or not trans then return nil end

    -- 1. Check if inventory is ready
    local success, itemList = trans:GetItemList(entity)
    local isLoaded = false

    if success == true then
        isLoaded = true
    end

    if not isLoaded then
        -- Inventory not streamed in yet. Abort check.
        return nil
    end

    -- 2. Check for Known CW Capacity Shard IDs (All tiers)
    if trans:HasItem(entity, ItemID.new(TweakDBID.new("Items.CWCapacityPermaReward_Uncommon"))) then return true end
    if trans:HasItem(entity, ItemID.new(TweakDBID.new("Items.CWCapacityPermaReward_Rare"))) then return true end
    if trans:HasItem(entity, ItemID.new(TweakDBID.new("Items.CWCapacityPermaReward_Epic"))) then return true end
    if trans:HasItem(entity, ItemID.new(TweakDBID.new("Items.CWCapacityPermaReward_Legendary"))) then return true end

    return false -- Loaded, but no shard found
end

-- ### CHECKS ###

-- Check Quest Facts (Gig completion)
local function CheckQuestFacts()
    local qs = Game.GetQuestsSystem()
    if not qs then return end

    local count = 0
    for _, cat in ipairs(CyberwareCapacityDB) do
        for _, entry in ipairs(cat.entries) do
            -- Only check if uncollected and has a fact
            if not IsCollected(entry.id) and entry.quest_fact then
                local factVal = qs:GetFactStr(entry.quest_fact)
                if factVal > 0 then
                    Utils.Log("Found completed Quest Fact for " .. entry.id)
                    Automation.SetItemStatus(entry.id, true)
                    count = count + 1
                end
            end
        end
    end
    if count > 0 then Utils.Log("Retroactively unlocked " .. count .. " items via Quest Facts.") end
end

-- ### OBSERVERS & PROXIMITY SCANNER ###

-- Cache for notifications to avoid spam
local _createdMappins = {}
local _mappinSnapped = {}
local _entityCache = {}

function Automation.StartScanner()
    if _cronTimerId then
        if _isDebug then Utils.Log("StartScanner called, but scanner is already running.", Utils.LogLevel.Debug) end
        return
    end

    if _isDebug then Utils.Log("Automation: Starting Proximity Scanner Loop.", Utils.LogLevel.Debug) end

    -- Start Passive Proximity Scanner (Cron Loop 1.0s)
    _unpauseTime = os.clock() -- Initialize Grace Period on Start
    _cronTimerId = Cron.Every(1.0, function()
        local currentTime = os.clock()
        local interval = _settings and _settings.scanner_interval or 5.0

        if (currentTime - _lastScanTime) >= interval then
            Automation.ProximityScan()
            _lastScanTime = currentTime
        end
    end)
end

function Automation.StopScanner()
    if _cronTimerId then
        Cron.Halt(_cronTimerId)
        _cronTimerId = nil
        Utils.Log("Automation: Stopped Proximity Scanner Loop.")
        _createdMappins = {} -- Reset mappins on stop
    end
end

function Automation.UpdateState()
    if _settings and _settings.automation_enabled then
        if CheckAllCollected() then
            StopScanner()
        else
            Automation.StartScanner()
        end
    else
        Automation.StopScanner()
    end
end

--- Periodic check for player proximity
-- Helper: Resolve Entity from Cache or DB ID
local function ResolveEntity(entry)
    -- 1. Try Weak Cache
    if _entityCache[entry.id] and not Ref.IsExpired(_entityCache[entry.id]) then
        return _entityCache[entry.id]
    end

    -- 2. Try FindEntityByID (if container_id exists — works for NPC bodies too)
    if entry.container_id then
        local success, hashVal = pcall(loadstring("return " .. tostring(entry.container_id)))
        if success and hashVal then
            local tid = entEntityID.new()
            tid.hash = hashVal
            local entity = Game.FindEntityByID(tid)
            if entity then
                _entityCache[entry.id] = Ref.Weak(entity)
                return entity
            end
        end
    end
    return nil
end

--- Periodic check for player proximity
function Automation.ProximityScan()
    local player = Game.GetPlayer()
    if not player then return end

    -- PAUSE CHECK: Suspend automation during Menus/Loading
    local isPaused = GameSession.IsPaused()

    if isPaused then
        _wasPaused = true
        return
    end

    -- Just unpaused?
    if _wasPaused then
        _unpauseTime = os.clock()
        _wasPaused = false
    end

    -- Grace Period Check (3.0s for Fade-In, or longer if Teleport Cooldown is active)
    local graceTime = 3.0
    if _unpauseTime > os.clock() then
        -- We are in a forced cooldown (Teleport)
        if _isDebug and math.fmod(os.clock(), 2.0) < 0.1 then -- Log occasionally
            Utils.Log("[Proximity] Waiting for Grace Period / Teleport Cooldown...", Utils.LogLevel.Debug)
        end
        return
    elseif (os.clock() - _unpauseTime) < graceTime then
        return
    end

    if _isDebug then
        local status = _settings and
            ("Enabled: " .. tostring(_settings.automation_enabled) .. ", Radius: " .. tostring(_settings.scanner_radius)) or
            "No Settings"
        Utils.Log("[Proximity] Scanning... " .. status, Utils.LogLevel.Debug)
    end

    local playerPos = player:GetWorldPosition()
    local radius = _settings and _settings.scanner_radius or 50.0
    local radiusSq = radius * radius
    local detectionDistSq = 25.0 * 25.0

    -- Iterate through DB to find uncollected items with coords
    for _, cat in ipairs(CyberwareCapacityDB) do
        for _, entry in ipairs(cat.entries) do
            if not IsCollected(entry.id) and entry.coords then
                -- Check Distance
                local dx = playerPos.x - entry.coords.x
                local dy = playerPos.y - entry.coords.y
                local dz = playerPos.z - entry.coords.z
                local distSq = (dx * dx) + (dy * dy) + (dz * dz)

                if distSq < radiusSq then
                    local entity = ResolveEntity(entry)

                    -- 1. Mappin Logic
                    if not _createdMappins[entry.id] then
                        -- Create new mappin (snapped if entity available)
                        Automation.CreateMappin(entry, entity)
                    elseif entity and not _mappinSnapped[entry.id] then
                        -- Upgrade to snapped mappin if entity streamed in
                        Automation.RemoveMappin(entry.id)
                        Automation.CreateMappin(entry, entity)
                    end

                    -- 2. Check Logic (Auto-Resolve)
                    Automation.CheckProximityTarget(entry, entity, distSq < detectionDistSq)
                else
                    -- Cleanup if out of range
                    if _createdMappins[entry.id] then
                        Automation.RemoveMappin(entry.id)
                    end
                    if _notified_cache[entry.id] then
                        _notified_cache[entry.id] = nil
                    end
                end
            elseif IsCollected(entry.id) then
                if _createdMappins[entry.id] then
                    Automation.RemoveMappin(entry.id)
                end
            end
        end
    end
end

function Automation.CreateMappin(entry, entity)
    local mappinData = MappinData.new()
    mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
    mappinData.variant = gamedataMappinVariant.ServicePointNetTrainerVariant
    mappinData.visibleThroughWalls = true

    local pos = Vector4.new(entry.coords.x, entry.coords.y, entry.coords.z + 1.0, 1.0) -- Lift slightly default

    -- Snap if entity provided
    if entity then
        pos = entity:GetWorldPosition()
        pos.z = pos.z + 0.5 -- slight offset
        _mappinSnapped[entry.id] = true
    else
        _mappinSnapped[entry.id] = false
    end

    local id = Game.GetMappinSystem():RegisterMappin(mappinData, pos)
    _createdMappins[entry.id] = id
end

function Automation.RemoveMappin(entryID)
    local id = _createdMappins[entryID]
    if id then
        Game.GetMappinSystem():UnregisterMappin(id)
        _createdMappins[entryID] = nil
        _mappinSnapped[entryID] = nil
    end
end

function Automation.CheckProximityTarget(entry, entity, isVeryClose)
    -- NOTIFICATION (First time only)
    if not _notified_cache[entry.id] then
        Utils.Notify("CW Capacity Shard detected: " .. entry.name)
        _notified_cache[entry.id] = true
    end

    -- AUTO-RESOLVE LOGIC (NPC body / container proximity check)
    if entity and isVeryClose then
        -- Entity found AND we are close (avoid long-range empty checks)
        local trans = Game.GetTransactionSystem()
        if trans then
            local result = HasAnyCWCapacityShard(entity, trans)

            if result == false then
                -- Verified Loaded AND Empty -> Auto-Collect
                Automation.SetItemStatus(entry.id, true)
                Utils.Notify("Verified: Looted. Auto-Collected: " .. entry.name)
                if _isDebug then
                    Utils.Log("[Loot] MATCH FOUND (Proximity Resolution): " .. entry.name,
                        Utils.LogLevel.Debug)
                end
                Automation.RemoveMappin(entry.id)
            elseif result == true then
                -- Found it! Ensure notify cache is populated so we don't annoy user
                if not _notified_cache[entry.id] then
                    Utils.Notify("CW Capacity Shard detected: " .. entry.name)
                    if _isDebug then Utils.Log("[Proximity] Shard Detected: " .. entry.name, Utils.LogLevel.Debug) end
                    _notified_cache[entry.id] = true
                end
            end
            -- If result is nil (Not Loaded), do nothing. Wait for next tick.
        end
    elseif isVeryClose then
        -- Entity NOT found (despawned/glitched), and we are close.
        Automation.SetItemStatus(entry.id, true)
        Utils.Notify("Verified: Entity missing. Auto-Collected: " .. entry.name)
        if _isDebug then Utils.Log("[Loot] MATCH FOUND (Missing Entity): " .. entry.name, Utils.LogLevel.Debug) end
        Automation.RemoveMappin(entry.id)
    end
end

-- Predictive Loot Logic: Resolve closest uncollected item for instant feedback
-- @param maxRadius (number) Maximum distance to search (100m for Autoloot compatibility)
-- @return (table|nil) The closest DB entry object, or nil if none found
function Automation.ResolveClosestUncollected(maxRadius)
    local player = Game.GetPlayer()
    if not player then return nil end

    local playerPos = player:GetWorldPosition()
    local radius = maxRadius or 100.0
    local radiusSq = radius * radius

    local closestEntry = nil
    local closestDistSq = radiusSq -- Initialize with max range

    for _, cat in ipairs(CyberwareCapacityDB) do
        for _, entry in ipairs(cat.entries) do
            -- Only check uncollected items with valid coordinates
            if not IsCollected(entry.id) and entry.coords then
                local dx = playerPos.x - entry.coords.x
                local dy = playerPos.y - entry.coords.y
                local dz = playerPos.z - entry.coords.z
                local distSq = (dx * dx) + (dy * dy) + (dz * dz)

                -- Find the absolute closest one
                if distSq < closestDistSq then
                    closestDistSq = distSq
                    closestEntry = entry
                end
            end
        end
    end

    if closestEntry then
        if _isDebug then
            Utils.Log("[Predict] Resolved closest item: " .. closestEntry.name .. " (DistSq: " .. closestDistSq .. ")",
                Utils.LogLevel.Debug)
        end
        return closestEntry
    end

    return nil
end

-- Public Scan Function (Called by Init and UI Open)
function Automation.Scan()
    CheckQuestFacts()
    Automation.ProximityScan()
end

-- ### INIT ###

--- Initialize Automation
-- @param sessionState (table) Player progress state
-- @param callbacks (table) UI callbacks (for onToggle/Save)
-- @param debugMode (boolean) Enable verbose logging
function Automation.Init(sessionState, callbacks, debugMode, settings)
    _sessionState = sessionState
    _callbacks = callbacks
    _isDebug = debugMode or false
    _settings = settings

    Utils.Log("Initializing... (Debug: " .. tostring(_isDebug) .. ")")

    -- Check if we are already done
    local isComplete, count, total = CheckAllCollected()
    if isComplete then
        Utils.Log(string.format("All items collected (%d/%d).", count, total))
    else
        Utils.Log(string.format("Automation Init: %d/%d collected.", count, total))
    end

    Utils.Log("Ready (Event-Driven Mode).")
end

return Automation

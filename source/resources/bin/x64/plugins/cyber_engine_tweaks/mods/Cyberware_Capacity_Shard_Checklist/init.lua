-- ======================================================================================
-- Mod Name: Cyberware Capacity Shard Checklist
-- Author: Spuddeh
-- Description: Main entry point and initialization logic.
-- Mod Version: 1.0.0
-- ======================================================================================

local CyberwareCapacityDB = require("db")
local GameSession = require("Modules/GameSession")
local ChecklistUI = require("Modules/ChecklistUI")
local SettingsUI = require("Modules/SettingsUI")
local Automation = require("Modules/Automation")
local Cron = require("Modules/Cron")
local Utils = require("Modules/Utils")

-- ### MOD STATE ###

local sessionState = {
    progress = {}
}

-- Global Settings (Default)
local settings = {
    lazy_mode = false,
    dev_mode_enabled = false
}

local isOverlayOpen = false
local isSessionActive = false
-- Runtime State (Non-persistent)
local runtimeState = {
    current_mappin = nil
}
local config_file = "config.json"

-- ### CONFIG IO ###

local function SaveConfig()
    local file = io.open(config_file, "w")
    if file then
        file:write(json.encode(settings))
        file:close()
    end
end

local function LoadConfig()
    local file = io.open(config_file, "r")
    if file then
        local content = file:read("*a")
        file:close()
        if content then
            local loaded = json.decode(content)
            for k, v in pairs(loaded) do
                settings[k] = v
            end
        end
    end
    -- Enforce defaults for new settings if missing
    if settings.automation_enabled == nil then settings.automation_enabled = true end
    if not settings.scanner_interval then settings.scanner_interval = 5.0 end
    if not settings.scanner_radius then settings.scanner_radius = 50.0 end
end

-- ### CALLBACKS ###

local uiCallbacks = {
    onToggle = function(id, value)
        -- Use Automation to handle state changes (triggers stop logic/debug logs)
        if Automation.SetItemStatus then
            Automation.SetItemStatus(id, value)
        else
            -- Fallback if Automation not ready (shouldn't happen)
            sessionState.progress[id] = value
        end
    end,

    onAction = function(action, entry)
        local player = GetPlayer()
        if not player then return end

        local function TeleportTo(coords, name)
            if coords then
                local pos = ToVector4 { x = coords.x, y = coords.y, z = coords.z, w = 1 }
                local rot = ToEulerAngles { roll = 0, pitch = 0, yaw = coords.yaw or 0 }
                Game.GetTeleportationFacility():Teleport(player, pos, rot)
                Utils.Log("Teleported to: " .. name)
            end
        end

        local function SetPin(coords, name)
            if runtimeState.current_mappin then
                Game.GetMappinSystem():UnregisterMappin(runtimeState.current_mappin)
                runtimeState.current_mappin = nil
            end
            if coords then
                local mappinData = MappinData.new()
                mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
                mappinData.variant = gamedataMappinVariant.CustomPositionVariant
                mappinData.visibleThroughWalls = true
                local pin_pos = Vector4.new(coords.x, coords.y, coords.z, 0)
                runtimeState.current_mappin = Game.GetMappinSystem():RegisterMappin(mappinData, pin_pos)
                Utils.Log("Map pin set for: " .. name)
            end
        end

        if action == "teleport" then
            Automation.OnTeleport()
            TeleportTo(entry.coords, entry.name)
        elseif action == "gig_teleport" then
            Automation.OnTeleport()
            TeleportTo(entry.gig_coords, entry.name .. " (Gig Start)")
        elseif action == "mappin" then
            SetPin(entry.coords, entry.name)
        elseif action == "gig_mappin" then
            SetPin(entry.gig_coords, entry.name .. " (Gig Start)")
        end
    end,

    -- Settings Callbacks being delegated to SettingsUI
    drawSettings = function()
        -- Define sub-callbacks for the SettingsUI module
        local settingsCallbacks = {
            onSettingChanged = function()
                Automation.UpdateState()
                SaveConfig()
            end,

            drawCustomSettings = function()
                -- No custom dev tools for this mod (unlike PSC which has Inspector)
            end
        }

        SettingsUI.Draw(settings, runtimeState, settingsCallbacks)
    end

    -- No drawCustomActions (no Give Item button for this mod)
}

-- ### EVENTS ###

registerForEvent("onInit", function()
    LoadConfig()

    -- No vendor hooks needed (CW Capacity Shards are not sold by vendors)
    -- No Inspector hooks needed

    -- PLAYER INVENTORY LISTENER: Detect Looting CW Capacity Shards
    -- Uses UIInventoryScriptableSystem for reliability (same as PSC/CSC)
    Observe("UIInventoryScriptableSystem", "OnInventoryItemAdded", function(_, request)
        if not isSessionActive then return end

        local itemID = request.itemID
        local tdbid = ItemID.GetTDBID(itemID)

        if not tdbid then return end

        local idString = tostring(tdbid)

        -- Match CW Capacity Shard TweakDB IDs
        if string.find(idString, "CWCapacityPermaReward") then
            if settings.dev_mode_enabled then
                Utils.Log("[Loot] CW Capacity Shard added to inventory. Triggering proximity resolution...",
                    Utils.LogLevel.Debug)
            end

            -- PREDICTIVE RESOLUTION: Check for closest uncollected entry (100m radius)
            local resolvedEntry = Automation.ResolveClosestUncollected(100.0)

            if resolvedEntry then
                -- Match Found! Mark collected immediately
                sessionState.progress[resolvedEntry.id] = true
                Utils.Notify("CW Capacity Shard Looted: " .. resolvedEntry.name)

                if settings.dev_mode_enabled then
                    Utils.Log("[Loot] MATCH FOUND: " .. resolvedEntry.name, Utils.LogLevel.Debug)
                end

                -- Cleanup Mappin if exists
                Automation.RemoveMappin(resolvedEntry.id)
            else
                -- No match in range. Fallback to full scan.
                if settings.dev_mode_enabled then
                    Utils.Log("[Loot] No entry found within 100m. Falling back to full scan.", Utils.LogLevel.Debug)
                end
                Automation.ProximityScan()
            end
        end
    end)

    -- GameSession Setup (CET Kit Style)
    GameSession.StoreInDir('sessions')
    GameSession.Persist(sessionState)

    -- GameSession Triggers
    GameSession.OnStart(function()
        Utils.Log("Game Session Started. Initializing Automation.")
        isSessionActive = true

        -- Initialize Automation (Inject Dependencies)
        Automation.Init(sessionState, uiCallbacks, settings.dev_mode_enabled, settings)

        -- Initial Kill Fact + Shard Scan (retroactive detection)
        Automation.CheckKillFacts()

        -- Initial Scan & Start Loop
        Automation.UpdateState()
    end)

    GameSession.OnEnd(function()
        Utils.Log("Game Session Ended. Cleanup.")
        isSessionActive = false

        Automation.StopScanner()
    end)

    GameSession.OnSave(function()
        SaveConfig()
    end)

    Utils.Log("Loaded (Wait for Session Start).")
end)

registerForEvent("onUpdate", function(deltaTime)
    Cron.Update(deltaTime)
end)

registerForEvent("onOverlayOpen", function()
    isOverlayOpen = true
    if isSessionActive then
        Automation.Scan() -- Force scan when user checks the list
    end
end)

registerForEvent("onOverlayClose", function()
    isOverlayOpen = false
end)

registerForEvent("onDraw", function()
    if isOverlayOpen then
        if isSessionActive then
            -- Pass all context explicitly to Draw (Stateless Pattern)
            -- Using "manual" mode: checkboxes enabled for user interaction
            ChecklistUI.Draw("CW Capacity Shard Checklist", true, CyberwareCapacityDB, sessionState.progress, settings,
                uiCallbacks, "manual")
        else
            ChecklistUI.DrawSplashScreen("CW Capacity Shard Checklist")
        end
    end
end)

-- ### CONSOLE COMMANDS ###

--- Toggles Debug Mode via Console
-- Usage: GetMod("Cyberware_Capacity_Shard_Checklist").ToggleDebug()
local function ToggleDebug()
    settings.dev_mode_enabled = not settings.dev_mode_enabled

    -- RE-INIT Automation to update debug state
    Automation.Init(sessionState, uiCallbacks, settings.dev_mode_enabled, settings)

    if settings.dev_mode_enabled then
        Utils.Log("Debug Mode ENABLED via Console.")
    else
        Utils.Log("Debug Mode DISABLED via Console.")
    end
    SaveConfig()
end

return {
    ToggleDebug = ToggleDebug
}

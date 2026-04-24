-- ======================================================================================
-- Mod Name: Cyberware Capacity Shard Checklist
-- Author: Spuddeh
-- Description: Main entry point and initialization logic.
-- Mod Version: 1.1.0
-- ======================================================================================

local CyberwareCapacityDB = require("db")
local GameSession         = require("Modules/GameSession")
local GameUI              = require("Modules/GameUI")
local ChecklistUI         = require("Modules/ChecklistUI")
local SettingsUI          = require("Modules/SettingsUI")
local Automation          = require("Modules/Automation")
local Utils               = require("Modules/Utils")
Utils.LogPrefix = IconGlyphs.Chip .. " [CW Capacity Shard Checklist] "

-- ### MOD STATE ###

local sessionState = {
    progress = {}
}

local settings = {
    lazy_mode         = false,
    dev_mode_enabled  = false
}

local isOverlayOpen   = false
local isSessionActive = false
local runtimeState    = { current_mappin = nil }
local config_file     = "config.json"

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
    if settings.automation_enabled == nil then settings.automation_enabled = true end
    if not settings.scanner_radius then settings.scanner_radius = 50.0 end
end

-- ### CALLBACKS ###

local uiCallbacks = {
    onToggle = function(id, value)
        if Automation.SetItemStatus then
            Automation.SetItemStatus(id, value)
        else
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
                Utils.Log(string.format("Teleported to: %s | clock=%.2f", name, os.clock()), Utils.LogLevel.Debug)
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
            TeleportTo(entry.coords, entry.name)
        elseif action == "gig_teleport" then
            TeleportTo(entry.gig_coords, entry.name .. " (Gig Start)")
        elseif action == "mappin" then
            SetPin(entry.coords, entry.name)
        elseif action == "gig_mappin" then
            SetPin(entry.gig_coords, entry.name .. " (Gig Start)")
        end
    end,

    drawSettings = function()
        SettingsUI.Draw(settings, runtimeState, {
            onSettingChanged = function()
                Automation.UpdateState()
                SaveConfig()
            end,
            drawCustomSettings = function() end
        })
    end
}

-- ### EVENTS ###

registerForEvent("onInit", function()
    local Engine = GetMod("0-Engine")
    if not Engine then
        spdlog.error("[CCSC] FATAL: 0-Engine not found. Install from Nexus (ID 27967).")
        return
    end
    local Mod = Engine.Register("Cyberware_Capacity_Shard_Checklist")

    LoadConfig()
    Utils.SetDebugMode(settings.dev_mode_enabled)

    GameSession.StoreInDir('sessions')
    GameSession.Persist(sessionState)

    GameSession.OnSave(function()
        SaveConfig()
    end)

    -- 0-Engine: combat and cutscene suppression
    Engine.Subscribe("CombatStateChanged", function(inCombat)
        Automation.SetInCombat(inCombat)
    end)
    Engine.Subscribe("SceneTierChanged", function(tier)
        Automation.SetInCutscene(tier > 1)
    end)

    -- GameSession: log every state change so we can see isLoaded + isPaused transitions.
    -- This reveals the exact loading screen lifecycle vs regular menu pauses.
    GameSession.On(function(state)
        Utils.Log(string.format("[CCSC] GameSession | loaded=%s paused=%s | clock=%.2f",
            tostring(state.isLoaded), tostring(state.isPaused), os.clock()), Utils.LogLevel.Debug)
    end)

    -- GameUI: replaces GameSession.OnPause/OnResume with faster, more specific events.
    -- OnLoadingStart fires via LoadingScreenProgressBarController::SetProgress —
    -- immediately when the loading screen initialises, before the bar moves.
    -- OnMenuOpen/Close handle vendors, pause menu, and all other menus.
    GameUI.OnLoadingStart(function()
        Utils.Log(string.format("[CCSC] GameUI.LoadingStart | clock=%.2f", os.clock()), Utils.LogLevel.Debug)
        Automation.SetMenuPaused(true)
    end)
    GameUI.OnLoadingFinish(function()
        Utils.Log(string.format("[CCSC] GameUI.LoadingFinish | clock=%.2f", os.clock()), Utils.LogLevel.Debug)
        Automation.SetMenuPaused(false)
    end)
    GameUI.OnMenuOpen(function()
        Utils.Log(string.format("[CCSC] GameUI.MenuOpen | clock=%.2f", os.clock()), Utils.LogLevel.Debug)
        Automation.SetMenuPaused(true)
    end)
    GameUI.OnMenuClose(function()
        Utils.Log(string.format("[CCSC] GameUI.MenuClose | clock=%.2f", os.clock()), Utils.LogLevel.Debug)
        Automation.SetMenuPaused(false)
    end)

    -- INVENTORY LISTENER: Detect CW Capacity Shard looting
    Observe("UIInventoryScriptableSystem", "OnInventoryItemAdded", function(_, request)
        if not isSessionActive then return end
        if not Automation.HasNearbyEntries() then return end

        local tdbid = ItemID.GetTDBID(request.itemID)
        if not tdbid then return end

        local idString = tostring(tdbid)

        if string.find(idString, "CWCapacityPermaReward") then
            if settings.dev_mode_enabled then
                Utils.Log("[Loot] CW Capacity Shard added to inventory. Triggering proximity resolution...",
                    Utils.LogLevel.Debug)
            end

            local resolvedEntry = Automation.ResolveClosestUncollected(100.0)

            if resolvedEntry then
                Automation.SetItemStatus(resolvedEntry.id, true)
                Utils.Notify("CW Capacity Shard Looted: " .. resolvedEntry.name)
                if settings.dev_mode_enabled then
                    Utils.Log("[Loot] MATCH FOUND: " .. resolvedEntry.name, Utils.LogLevel.Debug)
                end
            else
                if settings.dev_mode_enabled then
                    Utils.Log("[Loot] No entry found within 100m.", Utils.LogLevel.Debug)
                end
            end
        end
    end)

    -- PlayerInvalidated: resource cleanup only. Still fires on some vendor opens.
    Engine.Subscribe("PlayerInvalidated", function()
        Utils.Log(string.format("[CCSC] PlayerInvalidated | clock=%.2f", os.clock()), Utils.LogLevel.Debug)
        Automation.UnregisterItemSet()
    end)

    GameSession.OnEnd(function()
        Utils.Log(string.format("[CCSC] GameSession.OnEnd | clock=%.2f", os.clock()), Utils.LogLevel.Debug)
        isSessionActive = false
    end)

    Mod.WhenReady(function(_)
        local paused = GameSession.IsPaused()
        Utils.Log(string.format("[CCSC] WhenReady | IsPaused=%s | clock=%.2f", tostring(paused), os.clock()), Utils.LogLevel.Debug)
        isSessionActive = true

        Automation.Init(sessionState, uiCallbacks, settings.dev_mode_enabled, settings)
        Automation.UpdateState()
        if not paused then
            Automation.Scan()
        end
    end, nil, 2)

    Utils.Log("Loaded (Wait for Player Ready).")
end)

registerForEvent("onOverlayOpen", function()
    isOverlayOpen = true
    if isSessionActive then
        Automation.Scan()
    end
end)

registerForEvent("onOverlayClose", function()
    isOverlayOpen = false
end)

registerForEvent("onDraw", function()
    if isOverlayOpen then
        if isSessionActive then
            ChecklistUI.Draw("CW Capacity Shard Checklist", true, CyberwareCapacityDB,
                sessionState.progress, settings, uiCallbacks, "manual")
        else
            ChecklistUI.DrawSplashScreen("CW Capacity Shard Checklist")
        end
    end
end)

local function ToggleDebug()
    settings.dev_mode_enabled = not settings.dev_mode_enabled
    Utils.SetDebugMode(settings.dev_mode_enabled)
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

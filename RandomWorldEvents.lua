-- =========================================================
-- Random World Events (version 2.0.0.3) - FS25 Conversion
-- =========================================================
-- Random events that can occur. Settings can be changed!
-- =========================================================
-- Author: TisonK
-- =========================================================
-- COPYRIGHT NOTICE:
-- All rights reserved. Unauthorized redistribution, copying,
-- or claiming this code as your own is strictly prohibited.
-- Original author: TisonK
-- =========================================================

local modDirectory = g_currentModDirectory
local modName = g_currentModName

---@class RandomWorldEvents
RandomWorldEvents = {
    MOD_NAME = modName,
    
    events = {
        enabled = true,
        frequency = 5, 
        intensity = 2, 
        showNotifications = true,
        showWarnings = true,
        cooldown = 30, 
        
        weatherEvents = false,
        economicEvents = true,
        vehicleEvents = true,
        fieldEvents = true,
        wildlifeEvents = true,
        specialEvents = true,
        
        debugLevel = 1
    },
    
    debug = {
        enabled = false,
        debugLevel = 1,
        showDebugInfo = false
    },
    
    physics = {
        enabled = true,
        wheelGripMultiplier = 1.0,
        articulationDamping = 0.5,
        comStrength = 1.0,
        suspensionStiffness = 1.0,
        showPhysicsInfo = false,
        debugMode = false
    },
    
    modDirectory = modDirectory,
    isInitialized = false,
    needsSave = false,
    saveTime = nil,

    -- Per-tick handler table populated by event modules.
    -- Each entry: [name] = function(rweInstance) ... end
    -- Called from applyActiveEventEffects() while an event is active.
    tickHandlers = {}
}

RandomWorldEvents.EVENT_STATE = {
    activeEvent = nil,
    eventStartTime = 0,
    eventDuration = 0,
    eventData = {},
    history = {},
    cooldownUntil = 0
}

RandomWorldEvents.EVENTS = {}
RandomWorldEvents.eventCounter = 0

local RandomWorldEvents_mt = Class(RandomWorldEvents)

-- =====================
-- CORE FUNCTIONS
-- =====================

function RandomWorldEvents:new(mission)
    local self = setmetatable({}, RandomWorldEvents_mt)
    self.mission = mission
    
    self.settingsManager = self:createSettingsManager()
    
    self:loadSettings()
    
    self:registerConsoleCommands()
    
    Logging.info("[RandomWorldEvents] Core initialized successfully")
    
    return self
end

function RandomWorldEvents:createSettingsManager()
    local manager = {
        MOD_NAME = self.MOD_NAME,
        XMLTAG = "RandomWorldEvents",
        
        defaultConfig = {
            events = {
                enabled = true,
                frequency = 5,
                intensity = 2,
                showNotifications = true,
                showWarnings = true,
                cooldown = 30,
                weatherEvents = false,
                economicEvents = true,
                vehicleEvents = true,
                fieldEvents = true,
                wildlifeEvents = true,
                specialEvents = true,
                debugLevel = 1
            },
            debug = {
                enabled = false,
                debugLevel = 1,
                showDebugInfo = false
            },
            physics = {
                enabled = true,
                wheelGripMultiplier = 1.0,
                articulationDamping = 0.5,
                comStrength = 1.0,
                suspensionStiffness = 1.0,
                showPhysicsInfo = false,
                debugMode = false
            }
        }
    }
    
    -- Define methods after creating the table
    manager.getSavegameXmlFilePath = function()
        if g_currentMission and g_currentMission.missionInfo and g_currentMission.missionInfo.savegameDirectory then
            return ("%s/%s.xml"):format(g_currentMission.missionInfo.savegameDirectory, manager.MOD_NAME)
        end
        return nil
    end
    
    manager.loadSettings = function(settingsObject)
        local xmlPath = manager.getSavegameXmlFilePath()
        if xmlPath and fileExists(xmlPath) then
            local xml = XMLFile.load("rwe_Config", xmlPath)
            if xml then
                settingsObject.events.enabled = xml:getBool(manager.XMLTAG..".events.enabled", manager.defaultConfig.events.enabled)
                settingsObject.events.frequency = xml:getInt(manager.XMLTAG..".events.frequency", manager.defaultConfig.events.frequency)
                settingsObject.events.intensity = xml:getInt(manager.XMLTAG..".events.intensity", manager.defaultConfig.events.intensity)
                settingsObject.events.showNotifications = xml:getBool(manager.XMLTAG..".events.showNotifications", manager.defaultConfig.events.showNotifications)
                settingsObject.events.showWarnings = xml:getBool(manager.XMLTAG..".events.showWarnings", manager.defaultConfig.events.showWarnings)
                settingsObject.events.cooldown = xml:getInt(manager.XMLTAG..".events.cooldown", manager.defaultConfig.events.cooldown)
                settingsObject.events.weatherEvents = xml:getBool(manager.XMLTAG..".events.weatherEvents", manager.defaultConfig.events.weatherEvents)
                settingsObject.events.economicEvents = xml:getBool(manager.XMLTAG..".events.economicEvents", manager.defaultConfig.events.economicEvents)
                settingsObject.events.vehicleEvents = xml:getBool(manager.XMLTAG..".events.vehicleEvents", manager.defaultConfig.events.vehicleEvents)
                settingsObject.events.fieldEvents = xml:getBool(manager.XMLTAG..".events.fieldEvents", manager.defaultConfig.events.fieldEvents)
                settingsObject.events.wildlifeEvents = xml:getBool(manager.XMLTAG..".events.wildlifeEvents", manager.defaultConfig.events.wildlifeEvents)
                settingsObject.events.specialEvents = xml:getBool(manager.XMLTAG..".events.specialEvents", manager.defaultConfig.events.specialEvents)
                settingsObject.events.debugLevel = xml:getInt(manager.XMLTAG..".events.debugLevel", manager.defaultConfig.events.debugLevel)

                settingsObject.debug.enabled = xml:getBool(manager.XMLTAG..".debug.enabled", manager.defaultConfig.debug.enabled)
                settingsObject.debug.debugLevel = xml:getInt(manager.XMLTAG..".debug.debugLevel", manager.defaultConfig.debug.debugLevel)
                settingsObject.debug.showDebugInfo = xml:getBool(manager.XMLTAG..".debug.showDebugInfo", manager.defaultConfig.debug.showDebugInfo)
                
                settingsObject.physics.enabled = xml:getBool(manager.XMLTAG..".physics.enabled", manager.defaultConfig.physics.enabled)
                settingsObject.physics.wheelGripMultiplier = xml:getFloat(manager.XMLTAG..".physics.wheelGripMultiplier", manager.defaultConfig.physics.wheelGripMultiplier)
                settingsObject.physics.articulationDamping = xml:getFloat(manager.XMLTAG..".physics.articulationDamping", manager.defaultConfig.physics.articulationDamping)
                settingsObject.physics.comStrength = xml:getFloat(manager.XMLTAG..".physics.comStrength", manager.defaultConfig.physics.comStrength)
                settingsObject.physics.suspensionStiffness = xml:getFloat(manager.XMLTAG..".physics.suspensionStiffness", manager.defaultConfig.physics.suspensionStiffness)
                settingsObject.physics.showPhysicsInfo = xml:getBool(manager.XMLTAG..".physics.showPhysicsInfo", manager.defaultConfig.physics.showPhysicsInfo)
                settingsObject.physics.debugMode = xml:getBool(manager.XMLTAG..".physics.debugMode", manager.defaultConfig.physics.debugMode)
                
                xml:delete()
                return
            end
        end
        
        -- Use deep copy to avoid reference issues
        settingsObject.events = {}
        settingsObject.debug = {}
        settingsObject.physics = {}
        
        for k, v in pairs(manager.defaultConfig.events) do
            settingsObject.events[k] = v
        end
        for k, v in pairs(manager.defaultConfig.debug) do
            settingsObject.debug[k] = v
        end
        for k, v in pairs(manager.defaultConfig.physics) do
            settingsObject.physics[k] = v
        end
    end
    
    manager.saveSettings = function(settingsObject)
        local xmlPath = manager.getSavegameXmlFilePath()
        if not xmlPath then 
            Logging.warning("[RWE] No savegame path found")
            return 
        end
        
        local xml = XMLFile.create("rwe_Config", xmlPath, manager.XMLTAG)
        if xml then
            -- Save events settings
            xml:setBool(manager.XMLTAG..".events.enabled", settingsObject.events.enabled)
            xml:setInt(manager.XMLTAG..".events.frequency", settingsObject.events.frequency)
            xml:setInt(manager.XMLTAG..".events.intensity", settingsObject.events.intensity)
            xml:setBool(manager.XMLTAG..".events.showNotifications", settingsObject.events.showNotifications)
            xml:setBool(manager.XMLTAG..".events.showWarnings", settingsObject.events.showWarnings)
            xml:setInt(manager.XMLTAG..".events.cooldown", settingsObject.events.cooldown)
            xml:setBool(manager.XMLTAG..".events.weatherEvents", settingsObject.events.weatherEvents)
            xml:setBool(manager.XMLTAG..".events.economicEvents", settingsObject.events.economicEvents)
            xml:setBool(manager.XMLTAG..".events.vehicleEvents", settingsObject.events.vehicleEvents)
            xml:setBool(manager.XMLTAG..".events.fieldEvents", settingsObject.events.fieldEvents)
            xml:setBool(manager.XMLTAG..".events.wildlifeEvents", settingsObject.events.wildlifeEvents)
            xml:setBool(manager.XMLTAG..".events.specialEvents", settingsObject.events.specialEvents)
            xml:setInt(manager.XMLTAG..".events.debugLevel", settingsObject.events.debugLevel)
            
            -- Save debug settings
            xml:setBool(manager.XMLTAG..".debug.enabled", settingsObject.debug.enabled)
            xml:setInt(manager.XMLTAG..".debug.debugLevel", settingsObject.debug.debugLevel)
            xml:setBool(manager.XMLTAG..".debug.showDebugInfo", settingsObject.debug.showDebugInfo)
            
            -- Save physics settings
            xml:setBool(manager.XMLTAG..".physics.enabled", settingsObject.physics.enabled)
            xml:setFloat(manager.XMLTAG..".physics.wheelGripMultiplier", settingsObject.physics.wheelGripMultiplier)
            xml:setFloat(manager.XMLTAG..".physics.articulationDamping", settingsObject.physics.articulationDamping)
            xml:setFloat(manager.XMLTAG..".physics.comStrength", settingsObject.physics.comStrength)
            xml:setFloat(manager.XMLTAG..".physics.suspensionStiffness", settingsObject.physics.suspensionStiffness)
            xml:setBool(manager.XMLTAG..".physics.showPhysicsInfo", settingsObject.physics.showPhysicsInfo)
            xml:setBool(manager.XMLTAG..".physics.debugMode", settingsObject.physics.debugMode)
            
            xml:save()
            xml:delete()
            Logging.info("[RWE] Settings saved successfully")
        else
            Logging.error("[RWE] Failed to create XML file for settings")
        end
    end
    
    return manager
end

function RandomWorldEvents:loadSettings()
    if self.settingsManager and self.settingsManager.loadSettings then
        self.settingsManager.loadSettings(self)
        Logging.info("[RandomWorldEvents] Settings loaded")
    else
        Logging.error("[RandomWorldEvents] Settings manager not properly initialized")
    end
end

function RandomWorldEvents:saveSettings()
    if self.settingsManager and self.settingsManager.saveSettings then
        self.settingsManager.saveSettings(self)
        Logging.info("[RandomWorldEvents] Settings saved")
    else
        Logging.error("[RandomWorldEvents] Settings manager not properly initialized")
    end
end

function RandomWorldEvents:registerConsoleCommands()
    addConsoleCommand("rwe", "Random World Events commands", "consoleCommandHelp", self)
    addConsoleCommand("rweStatus", "Show RWE status", "consoleCommandStatus", self)
    addConsoleCommand("rweTest", "Test random event", "consoleCommandTest", self)
    addConsoleCommand("rweEnd", "End current event", "consoleCommandEnd", self)
    addConsoleCommand("rweDebug", "Toggle debug mode", "consoleCommandDebug", self)
    addConsoleCommand("rweList", "List available events", "consoleCommandList", self)
    addConsoleCommand("rweSettings", "Open settings screen", "consoleCommandSettings", self)
    
    Logging.info("[RandomWorldEvents] Console commands registered")
end

-- =====================
-- EVENT SYSTEM
-- =====================

function RandomWorldEvents:getFarmId()
    return g_currentMission and g_currentMission.player and g_currentMission.player.farmId or 0
end

function RandomWorldEvents:getVehicle()
    return g_currentMission and g_currentMission.controlledVehicle or nil
end

function RandomWorldEvents:registerEvent(eventData)
    self.eventCounter = self.eventCounter + 1
    self.EVENTS[eventData.name] = eventData
    Logging.info("[RWE] Registered event: " .. eventData.name)
    return eventData.name
end

-- Register a per-tick handler called while any event is active.
-- name   : string key (used for deduplication/replacement)
-- handler: function(rweInstance) called each frame during an active event
function RandomWorldEvents:registerTickHandler(name, handler)
    self.tickHandlers[name] = handler
    Logging.info("[RWE] Registered tick handler: " .. name)
end

function RandomWorldEvents:triggerRandomEvent()
    if not self.events.enabled then
        Logging.info("[RWE] Events disabled")
        return false
    end
    
    if self.EVENT_STATE.activeEvent ~= nil then
        Logging.info("[RWE] Event already active: " .. tostring(self.EVENT_STATE.activeEvent))
        return false
    end
    
    local available = {}
    for eventId, event in pairs(self.EVENTS) do
        local categoryKey = event.category .. "Events"
        local categoryEnabled = self.events[categoryKey]
        local canTrigger = event.canTrigger()
        local intensityOk = self.events.intensity >= (event.minIntensity or 1)
        
        if categoryEnabled and canTrigger and intensityOk then
            table.insert(available, eventId)
        end
    end
    
    if #available == 0 then
        Logging.info("[RWE] No events available to trigger")
        return false
    end
    
    local eventId = available[math.random(1, #available)]
    local event = self.EVENTS[eventId]
    
    self.EVENT_STATE.activeEvent = eventId
    self.EVENT_STATE.eventStartTime = g_currentMission.time
    
    local duration = 0
    if type(event.duration) == "table" then
        duration = math.random(event.duration.min, event.duration.max) * 60000
    end
    self.EVENT_STATE.eventDuration = duration
    
    Logging.info("[RWE] Event triggered: " .. eventId .. " (Duration: " .. (duration / 60000) .. " minutes)")
    
    local message = event.onStart(self.events.intensity)
    if message and self.events.showNotifications then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
    end
    
    return true
end

-- =====================
-- PHYSICS SYSTEM (FS25)
-- =====================

function RandomWorldEvents:updatePhysics(vehicle)
    if not self.physics.enabled or vehicle == nil then
        return
    end

    if vehicle.getIsActiveForInput == nil or not vehicle:getIsActiveForInput() then
        return
    end

    if vehicle.wheels and self.physics.wheelGripMultiplier then
        local grip = self.physics.wheelGripMultiplier
        for _, wheel in pairs(vehicle.wheels) do
            if wheel.physics ~= nil then
                wheel.physics.frictionScale = grip
            end
        end
    end

    if vehicle.wheels and self.physics.suspensionStiffness then
        for _, wheel in pairs(vehicle.wheels) do
            if wheel.suspension ~= nil then
                local originalForce = wheel.suspension.originalSpringForce or wheel.suspension.springForce
                wheel.suspension.originalSpringForce = originalForce
                wheel.suspension.springForce = originalForce * self.physics.suspensionStiffness
            end
        end
    end
end

-- =====================
-- UPDATE LOOPS
-- =====================

function RandomWorldEvents:update(dt)
    if not self.isInitialized then
        return
    end
    
    -- Event system update
    if self.events.enabled then
        if g_currentMission.time > (self.EVENT_STATE.cooldownUntil or 0) then
            local chance = self.events.frequency * 0.001
            if math.random() <= chance then
                self:triggerRandomEvent()
                local cooldownMs = self.events.cooldown * 60000
                local frequencyFactor = (11 - self.events.frequency) / 10
                self.EVENT_STATE.cooldownUntil = g_currentMission.time + (cooldownMs * frequencyFactor)
            end
        end
    end
    
    if self.EVENT_STATE.activeEvent then
        self:applyActiveEventEffects()
        
        if g_currentMission.time > (self.EVENT_STATE.eventStartTime + (self.EVENT_STATE.eventDuration or 0)) then
            local event = self.EVENTS[self.EVENT_STATE.activeEvent]
            if event and event.onEnd then
                local message = event.onEnd()
                if message and self.events.showNotifications then
                    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
                end
            end
            Logging.info("[RWE] Event ended: " .. tostring(self.EVENT_STATE.activeEvent))
            self.EVENT_STATE.activeEvent = nil
        end
    end
    
    if self.physics.enabled then
        local vehicle = g_currentMission.controlledVehicle
        if vehicle then
            if PhysicsUtils and PhysicsUtils.applyAdvancedPhysics then
                PhysicsUtils:applyAdvancedPhysics(vehicle)
            else
                self:updatePhysics(vehicle)
            end
        end
    end
end

-- Called each frame while an event is active. Dispatches to all registered
-- tick handlers so event modules can apply continuous per-frame effects
-- (e.g. vehicle speed boost reapplication) without monkey-patching :update.
function RandomWorldEvents:applyActiveEventEffects()
    for _, handler in pairs(self.tickHandlers) do
        handler(self)
    end
end

-- =====================
-- CONSOLE COMMANDS
-- =====================

function RandomWorldEvents:consoleCommandHelp()
    print("=== Random World Events Commands ===")
    print("rwe          - Show this help")
    print("rweStatus    - Show current status")
    print("rweTest      - Force-trigger random event")
    print("rweEnd       - End current event")
    print("rweSettings  - Open settings screen (also F3)")
    print("rweDebug on|off - Toggle debug mode")
    print("rweList [category] - List registered events")
    print("================================")
    return "Random World Events commands listed above"
end

function RandomWorldEvents:consoleCommandStatus()
    local status = string.format(
        "=== RWE Status ===\n" ..
        "Events enabled: %s\n" ..
        "Frequency: %d/10\n" ..
        "Intensity: %d/5\n" ..
        "Active event: %s\n" ..
        "Cooldown active: %s\n" ..
        "Physics enabled: %s\n" ..
        "=========================",
        tostring(self.events.enabled),
        self.events.frequency,
        self.events.intensity,
        self.EVENT_STATE.activeEvent or "None",
        tostring(g_currentMission.time < self.EVENT_STATE.cooldownUntil),
        tostring(self.physics.enabled)
    )
    print(status)
    return status
end

function RandomWorldEvents:consoleCommandTest()
    local success = self:triggerRandomEvent()
    if success then
        return "Random event triggered successfully"
    else
        return "Failed to trigger random event"
    end
end

function RandomWorldEvents:consoleCommandEnd()
    if not self.EVENT_STATE.activeEvent then
        return "No active event to end"
    end
    
    local event = self.EVENTS[self.EVENT_STATE.activeEvent]
    if event and event.onEnd then
        local message = event.onEnd()
        if message then
            if self.events.showNotifications then
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
            end
        end
    end
    
    self.EVENT_STATE.activeEvent = nil
    return "Event ended"
end

function RandomWorldEvents:consoleCommandDebug(mode)
    if mode == "on" then
        self.debug.enabled = true
        self.debug.showDebugInfo = true
        return "Debug mode ENABLED"
    elseif mode == "off" then
        self.debug.enabled = false
        self.debug.showDebugInfo = false
        return "Debug mode DISABLED"
    else
        self.debug.enabled = not self.debug.enabled
        self.debug.showDebugInfo = self.debug.enabled
        return "Debug mode: " .. (self.debug.enabled and "ENABLED" or "DISABLED")
    end
end

function RandomWorldEvents:consoleCommandList(category)
    print("=== Available Events ===")
    local total = 0
    for name, event in pairs(self.EVENTS) do
        if not category or event.category == category then
            print(string.format("%s (%s)", name, event.category))
            total = total + 1
        end
    end
    print(string.format("Total: %d events", total))
    print("========================")
    return string.format("Listed %d events", total)
end

-- Settings are now in ESC > Settings > Random World Events.
function RandomWorldEvents:consoleCommandSettings()
    return "Settings: open ESC > Settings and scroll to 'Random World Events'"
end

-- =====================
-- EVENT MODULES LOADER
-- =====================

function RandomWorldEvents:loadEventModules()
    -- Process any pending registrations that were collected
    if RandomWorldEvents and RandomWorldEvents.pendingRegistrations then
        Logging.info("[RWE] Processing " .. #RandomWorldEvents.pendingRegistrations .. " pending registrations")
        for _, registrationFunc in ipairs(RandomWorldEvents.pendingRegistrations) do
            if type(registrationFunc) == "function" then
                registrationFunc()
            end
        end
        RandomWorldEvents.pendingRegistrations = {}
        Logging.info("[RWE] All pending registrations processed")
    end
    
    -- PhysicsUtils self-initializes via the pendingRegistrations queue above;
    -- no second :new() call needed here.

    Logging.info("[RWE] Loaded " .. self.eventCounter .. " events")
end

-- =====================
-- GUI LOADER
-- =====================

function RandomWorldEvents:loadGUI()
    -- Settings are injected into ESC > Settings via RWESettingsIntegration (hooks pattern).
    -- No custom screen registration needed.
    Logging.info("[RWE] GUI ready (settings via InGameMenuSettingsFrame hook)")
end

-- =====================
-- FS25 INTEGRATION
-- =====================

local rweManager

local function load(mission)
    if rweManager == nil then
        Logging.info("[RandomWorldEvents] Initializing...")
        
        -- Create the manager
        rweManager = RandomWorldEvents:new(mission)
        
        if not rweManager then
            Logging.error("[RWE] Failed to create RandomWorldEvents instance")
            return
        end
        
        -- Store in global namespace BEFORE loading modules
        getfenv(0)["g_RandomWorldEvents"] = rweManager
        
        -- Now load event modules (they need g_RandomWorldEvents to exist)
        rweManager:loadEventModules()

        -- Mark as initialized
        rweManager.isInitialized = true
        
        -- Show notification
        if rweManager.events.enabled and rweManager.events.showNotifications then
            mission:addIngameNotification(
                FSBaseMission.INGAME_NOTIFICATION_OK,
                "Random World Events v2.0 loaded"
            )
        end
        
        Logging.info("[RandomWorldEvents] Initialized successfully with " .. rweManager.eventCounter .. " events")
    end
end

local function update(mission, dt)
    if rweManager and rweManager.isInitialized then
        rweManager:update(dt)
    end
end

local function delete(mission)
    if rweManager then
        rweManager:saveSettings()
        rweManager = nil
        getfenv(0)["g_RandomWorldEvents"] = nil
        Logging.info("[RandomWorldEvents] Shutting down")
    end
end

local function keyEvent(unicode, sym, modifier, isDown)
    if not isDown or not rweManager then return end

    if sym == 284 then -- F3 — hint: settings are in ESC > Settings
        if g_currentMission then
            g_currentMission:addIngameNotification(
                FSBaseMission.INGAME_NOTIFICATION_INFO,
                "RWE: Open ESC > Settings to configure Random World Events"
            )
        end
    elseif sym == 290 then -- F9 — force-trigger a random event
        rweManager:triggerRandomEvent()
    end
end

local function loadFinished(mission, ...)
    if rweManager and not rweManager.guiLoaded then
        rweManager:loadGUI()
        rweManager.guiLoaded = true
    end
end

-- Hook into FS25
Mission00.load = Utils.prependedFunction(Mission00.load, load)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadFinished)
FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, update)
FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, delete)
FSBaseMission.keyEvent = Utils.appendedFunction(FSBaseMission.keyEvent, keyEvent)

Logging.info("========================================")
Logging.info("   FS25 Random World Events v2.0.0.3   ")
Logging.info("           Successfully Loaded          ")
Logging.info("     Type 'rwe' in console for help     ")
Logging.info("========================================")

return RandomWorldEvents
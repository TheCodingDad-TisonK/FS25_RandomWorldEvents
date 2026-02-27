-- =========================================================
-- Random World Events (version 2.0.0.2) - FS25
-- Settings integration — hooks into InGameMenuSettingsFrame
-- Pattern: FS25_NPCFavor NPCSettingsIntegration
-- Author: TisonK
-- =========================================================

RWESettingsIntegration = {}
RWESettingsIntegration_mt = Class(RWESettingsIntegration)

-- Dropdown option tables
RWESettingsIntegration.frequencyOptions = {"1","2","3","4","5","6","7","8","9","10"}
RWESettingsIntegration.frequencyValues  = {1,2,3,4,5,6,7,8,9,10}

RWESettingsIntegration.intensityOptions = {"1","2","3","4","5"}
RWESettingsIntegration.intensityValues  = {1,2,3,4,5}

RWESettingsIntegration.cooldownOptions = {"5","10","15","30","60","120","240"}
RWESettingsIntegration.cooldownValues  = {5,10,15,30,60,120,240}

RWESettingsIntegration.physicsMultOptions = {"0.50","0.75","1.00","1.25","1.50","2.00"}
RWESettingsIntegration.physicsMultValues  = {0.50,0.75,1.00,1.25,1.50,2.00}

-- =========================================================
-- Hook: called when ESC > Settings frame opens
-- =========================================================

function RWESettingsIntegration:onFrameOpen()
    -- 'self' is the InGameMenuSettingsFrame instance
    if self.rwe_initDone then
        return
    end

    RWESettingsIntegration:addSettingsElements(self)

    self.gameSettingsLayout:invalidateLayout()

    if self.updateAlternatingElements then
        self:updateAlternatingElements(self.gameSettingsLayout)
    end
    if self.updateGeneralSettings then
        self:updateGeneralSettings(self.gameSettingsLayout)
    end

    self.rwe_initDone = true
    Logging.info("[RWE] Settings controls added to InGameMenuSettingsFrame")

    RWESettingsIntegration:updateSettingsUI(self)
end

-- =========================================================
-- Add all settings elements to the game settings layout
-- =========================================================

function RWESettingsIntegration:addSettingsElements(frame)
    -- Section header
    RWESettingsIntegration:addSectionHeader(frame,
        g_i18n:getText("rwe_section") or "Random World Events"
    )

    -- Enable Events
    frame.rwe_eventsEnabled = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEEventsEnabledChanged",
        g_i18n:getText("rwe_events_enabled_short") or "Enable Events",
        g_i18n:getText("rwe_events_enabled_long") or "Enable or disable all random events"
    )

    -- Frequency
    frame.rwe_frequency = RWESettingsIntegration:addMultiTextOption(
        frame, "onRWEFrequencyChanged",
        RWESettingsIntegration.frequencyOptions,
        "Event Frequency",
        "How often events fire (1=rare, 10=frequent)"
    )

    -- Intensity
    frame.rwe_intensity = RWESettingsIntegration:addMultiTextOption(
        frame, "onRWEIntensityChanged",
        RWESettingsIntegration.intensityOptions,
        "Event Intensity",
        "Strength of event effects (1=mild, 5=extreme)"
    )

    -- Cooldown
    frame.rwe_cooldown = RWESettingsIntegration:addMultiTextOption(
        frame, "onRWECooldownChanged",
        RWESettingsIntegration.cooldownOptions,
        "Cooldown (minutes)",
        "Minimum in-game minutes between events"
    )

    -- Notifications / Warnings
    frame.rwe_notifications = RWESettingsIntegration:addBinaryOption(
        frame, "onRWENotificationsChanged",
        "Show Notifications",
        "Display event notifications on screen"
    )

    frame.rwe_warnings = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEWarningsChanged",
        "Show Warnings",
        "Show event warning messages"
    )

    -- Category toggles
    frame.rwe_economicEvents = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEEconomicChanged",
        "Economic Events",
        "Enable market and economic events"
    )

    frame.rwe_vehicleEvents = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEVehicleChanged",
        "Vehicle Events",
        "Enable vehicle events (speed, fuel, damage)"
    )

    frame.rwe_fieldEvents = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEFieldChanged",
        "Field Events",
        "Enable crop and field events"
    )

    frame.rwe_wildlifeEvents = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEWildlifeChanged",
        "Wildlife Events",
        "Enable wildlife and animal events"
    )

    frame.rwe_specialEvents = RWESettingsIntegration:addBinaryOption(
        frame, "onRWESpecialChanged",
        "Special Events",
        "Enable time, XP, and special events"
    )

    -- Physics section
    frame.rwe_physicsEnabled = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEPhysicsEnabledChanged",
        "Enable Physics Override",
        "Apply terrain-aware wheel grip and suspension"
    )

    frame.rwe_wheelGrip = RWESettingsIntegration:addMultiTextOption(
        frame, "onRWEWheelGripChanged",
        RWESettingsIntegration.physicsMultOptions,
        "Wheel Grip Multiplier",
        "Scale terrain grip values (1.00 = default)"
    )

    frame.rwe_suspensionStiffness = RWESettingsIntegration:addMultiTextOption(
        frame, "onRWESuspensionChanged",
        RWESettingsIntegration.physicsMultOptions,
        "Suspension Stiffness",
        "Scale suspension spring force (1.00 = default)"
    )

    frame.rwe_showPhysicsInfo = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEShowPhysicsInfoChanged",
        "Show Physics Info",
        "Log per-vehicle speed and grip data each frame"
    )

    frame.rwe_debugMode = RWESettingsIntegration:addBinaryOption(
        frame, "onRWEDebugChanged",
        "RWE Debug Mode",
        "Show verbose Random World Events debug output"
    )
end

-- =========================================================
-- GUI Element Builders (FS25 profile-based)
-- =========================================================

function RWESettingsIntegration:addSectionHeader(frame, text)
    local textElement = TextElement.new()
    local textElementProfile = g_gui:getProfile("fs25_settingsSectionHeader")
    textElement.name = "sectionHeader"
    textElement:loadProfile(textElementProfile, true)
    textElement:setText(text)
    frame.gameSettingsLayout:addElement(textElement)
    textElement:onGuiSetupFinished()
end

function RWESettingsIntegration:addBinaryOption(frame, callbackName, title, tooltip)
    local bitMap = BitmapElement.new()
    local bitMapProfile = g_gui:getProfile("fs25_multiTextOptionContainer")
    bitMap:loadProfile(bitMapProfile, true)

    local binaryOption = BinaryOptionElement.new()
    binaryOption.useYesNoTexts = true
    local binaryOptionProfile = g_gui:getProfile("fs25_settingsBinaryOption")
    binaryOption:loadProfile(binaryOptionProfile, true)
    binaryOption.target = RWESettingsIntegration
    binaryOption:setCallback("onClickCallback", callbackName)

    local titleElement = TextElement.new()
    local titleProfile = g_gui:getProfile("fs25_settingsMultiTextOptionTitle")
    titleElement:loadProfile(titleProfile, true)
    titleElement:setText(title)

    local tooltipElement = TextElement.new()
    local tooltipProfile = g_gui:getProfile("fs25_multiTextOptionTooltip")
    tooltipElement.name = "ignore"
    tooltipElement:loadProfile(tooltipProfile, true)
    tooltipElement:setText(tooltip)

    binaryOption:addElement(tooltipElement)
    bitMap:addElement(binaryOption)
    bitMap:addElement(titleElement)

    binaryOption:onGuiSetupFinished()
    titleElement:onGuiSetupFinished()
    tooltipElement:onGuiSetupFinished()

    frame.gameSettingsLayout:addElement(bitMap)
    bitMap:onGuiSetupFinished()

    return binaryOption
end

function RWESettingsIntegration:addMultiTextOption(frame, callbackName, texts, title, tooltip)
    local bitMap = BitmapElement.new()
    local bitMapProfile = g_gui:getProfile("fs25_multiTextOptionContainer")
    bitMap:loadProfile(bitMapProfile, true)

    local multiTextOption = MultiTextOptionElement.new()
    local multiTextOptionProfile = g_gui:getProfile("fs25_settingsMultiTextOption")
    multiTextOption:loadProfile(multiTextOptionProfile, true)
    multiTextOption.target = RWESettingsIntegration
    multiTextOption:setCallback("onClickCallback", callbackName)
    multiTextOption:setTexts(texts)

    local titleElement = TextElement.new()
    local titleProfile = g_gui:getProfile("fs25_settingsMultiTextOptionTitle")
    titleElement:loadProfile(titleProfile, true)
    titleElement:setText(title)

    local tooltipElement = TextElement.new()
    local tooltipProfile = g_gui:getProfile("fs25_multiTextOptionTooltip")
    tooltipElement.name = "ignore"
    tooltipElement:loadProfile(tooltipProfile, true)
    tooltipElement:setText(tooltip)

    multiTextOption:addElement(tooltipElement)
    bitMap:addElement(multiTextOption)
    bitMap:addElement(titleElement)

    multiTextOption:onGuiSetupFinished()
    titleElement:onGuiSetupFinished()
    tooltipElement:onGuiSetupFinished()

    frame.gameSettingsLayout:addElement(bitMap)
    bitMap:onGuiSetupFinished()

    return multiTextOption
end

-- =========================================================
-- Update UI from current settings
-- =========================================================

-- Returns index of value in table closest to target
function RWESettingsIntegration:findValueIndex(values, target)
    local bestIdx = 1
    local bestDiff = math.huge
    for i, v in ipairs(values) do
        local diff = math.abs(v - target)
        if diff < bestDiff then
            bestDiff = diff
            bestIdx = i
        end
    end
    return bestIdx
end

function RWESettingsIntegration:updateSettingsUI(frame)
    if not frame.rwe_initDone then return end

    local rwe = g_RandomWorldEvents
    if not rwe then return end

    local ev = rwe.events
    local ph = rwe.physics

    -- Events section
    if frame.rwe_eventsEnabled then
        frame.rwe_eventsEnabled:setIsChecked(ev.enabled == true, false, false)
    end
    if frame.rwe_frequency then
        frame.rwe_frequency:setState(RWESettingsIntegration:findValueIndex(
            RWESettingsIntegration.frequencyValues, ev.frequency or 5
        ))
    end
    if frame.rwe_intensity then
        frame.rwe_intensity:setState(RWESettingsIntegration:findValueIndex(
            RWESettingsIntegration.intensityValues, ev.intensity or 3
        ))
    end
    if frame.rwe_cooldown then
        frame.rwe_cooldown:setState(RWESettingsIntegration:findValueIndex(
            RWESettingsIntegration.cooldownValues, ev.cooldown or 30
        ))
    end
    if frame.rwe_notifications then
        frame.rwe_notifications:setIsChecked(ev.showNotifications == true, false, false)
    end
    if frame.rwe_warnings then
        frame.rwe_warnings:setIsChecked(ev.showWarnings == true, false, false)
    end
    if frame.rwe_economicEvents then
        frame.rwe_economicEvents:setIsChecked(ev.economicEvents == true, false, false)
    end
    if frame.rwe_vehicleEvents then
        frame.rwe_vehicleEvents:setIsChecked(ev.vehicleEvents == true, false, false)
    end
    if frame.rwe_fieldEvents then
        frame.rwe_fieldEvents:setIsChecked(ev.fieldEvents == true, false, false)
    end
    if frame.rwe_wildlifeEvents then
        frame.rwe_wildlifeEvents:setIsChecked(ev.wildlifeEvents == true, false, false)
    end
    if frame.rwe_specialEvents then
        frame.rwe_specialEvents:setIsChecked(ev.specialEvents == true, false, false)
    end

    -- Physics section
    if frame.rwe_physicsEnabled then
        frame.rwe_physicsEnabled:setIsChecked(ph.enabled == true, false, false)
    end
    if frame.rwe_wheelGrip then
        frame.rwe_wheelGrip:setState(RWESettingsIntegration:findValueIndex(
            RWESettingsIntegration.physicsMultValues, ph.wheelGripMultiplier or 1.0
        ))
    end
    if frame.rwe_suspensionStiffness then
        frame.rwe_suspensionStiffness:setState(RWESettingsIntegration:findValueIndex(
            RWESettingsIntegration.physicsMultValues, ph.suspensionStiffness or 1.0
        ))
    end
    if frame.rwe_showPhysicsInfo then
        frame.rwe_showPhysicsInfo:setIsChecked(ph.showPhysicsInfo == true, false, false)
    end
    if frame.rwe_debugMode then
        frame.rwe_debugMode:setIsChecked(ph.debugMode == true, false, false)
    end
end

function RWESettingsIntegration:updateGameSettings()
    -- 'self' is InGameMenuSettingsFrame
    RWESettingsIntegration:updateSettingsUI(self)
end

-- =========================================================
-- Callback Handlers
-- =========================================================

local function applyEventSetting(key, value)
    if not g_RandomWorldEvents then return end
    g_RandomWorldEvents.events[key] = value
    g_RandomWorldEvents:saveSettings()
    Logging.info("[RWE] events." .. key .. " = " .. tostring(value))
end

local function applyPhysicsSetting(key, value)
    if not g_RandomWorldEvents then return end
    g_RandomWorldEvents.physics[key] = value
    g_RandomWorldEvents:saveSettings()
    Logging.info("[RWE] physics." .. key .. " = " .. tostring(value))
end

function RWESettingsIntegration:onRWEEventsEnabledChanged(state)
    applyEventSetting("enabled", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEFrequencyChanged(state)
    applyEventSetting("frequency", RWESettingsIntegration.frequencyValues[state] or 5)
end

function RWESettingsIntegration:onRWEIntensityChanged(state)
    applyEventSetting("intensity", RWESettingsIntegration.intensityValues[state] or 3)
end

function RWESettingsIntegration:onRWECooldownChanged(state)
    applyEventSetting("cooldown", RWESettingsIntegration.cooldownValues[state] or 30)
end

function RWESettingsIntegration:onRWENotificationsChanged(state)
    applyEventSetting("showNotifications", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEWarningsChanged(state)
    applyEventSetting("showWarnings", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEEconomicChanged(state)
    applyEventSetting("economicEvents", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEVehicleChanged(state)
    applyEventSetting("vehicleEvents", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEFieldChanged(state)
    applyEventSetting("fieldEvents", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEWildlifeChanged(state)
    applyEventSetting("wildlifeEvents", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWESpecialChanged(state)
    applyEventSetting("specialEvents", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEPhysicsEnabledChanged(state)
    applyPhysicsSetting("enabled", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEWheelGripChanged(state)
    applyPhysicsSetting("wheelGripMultiplier", RWESettingsIntegration.physicsMultValues[state] or 1.0)
end

function RWESettingsIntegration:onRWESuspensionChanged(state)
    applyPhysicsSetting("suspensionStiffness", RWESettingsIntegration.physicsMultValues[state] or 1.0)
end

function RWESettingsIntegration:onRWEShowPhysicsInfoChanged(state)
    applyPhysicsSetting("showPhysicsInfo", state == BinaryOptionElement.STATE_RIGHT)
end

function RWESettingsIntegration:onRWEDebugChanged(state)
    applyPhysicsSetting("debugMode", state == BinaryOptionElement.STATE_RIGHT)
end

-- =========================================================
-- Initialize hooks (runs at file load time)
-- =========================================================

local function initHooks()
    if not InGameMenuSettingsFrame then
        return
    end

    InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(
        InGameMenuSettingsFrame.onFrameOpen,
        RWESettingsIntegration.onFrameOpen
    )

    if InGameMenuSettingsFrame.updateGameSettings then
        InGameMenuSettingsFrame.updateGameSettings = Utils.appendedFunction(
            InGameMenuSettingsFrame.updateGameSettings,
            RWESettingsIntegration.updateGameSettings
        )
    end
end

initHooks()

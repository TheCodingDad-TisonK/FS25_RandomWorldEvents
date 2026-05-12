-- =========================================================
-- Random World Events - Settings Integration
-- =========================================================
-- Adds RWE settings to ESC > Settings > Game Settings page.
-- Uses the cloning pattern from Worker Costs / Soil Fertilizer.
-- =========================================================
-- Author: TisonK
-- =========================================================

RWESettingsIntegration = {}
RWESettingsIntegration_mt = Class(RWESettingsIntegration)

-- Dropdown option tables
RWESettingsIntegration.frequencyOptions = {"1","2","3","4","5","6","7","8","9","10"}
RWESettingsIntegration.intensityOptions = {"1","2","3","4","5"}
RWESettingsIntegration.cooldownOptions  = {"5 min","10 min","15 min","30 min","60 min","120 min","240 min"}
RWESettingsIntegration.cooldownValues   = {5,10,15,30,60,120,240}
RWESettingsIntegration.hudScaleOptions  = {"0.6x","0.8x","1.0x","1.2x","1.5x","1.8x"}
RWESettingsIntegration.hudScaleValues   = {0.6,0.8,1.0,1.2,1.5,1.8}
RWESettingsIntegration.physicsMultOptions = {"0.50x","0.75x","1.00x","1.25x","1.50x","2.00x"}
RWESettingsIntegration.physicsMultValues  = {0.50,0.75,1.00,1.25,1.50,2.00}

function RWESettingsIntegration:inject(frame)
    if self.injected then return end

    -- 'frame' is the InGameMenuSettingsFrame instance.
    local layout = frame.generalSettingsLayout
    if not layout then
        Logging.warning("[RWE] Settings layout not found, cannot inject!")
        return
    end

    Logging.info("[RWE] Injecting settings into InGameMenuSettingsFrame...")

    -- ── Main header ───────────────────────────────────────
    RWEUIHelper.createSection(layout, "rwe_section")

    self.eventsEnabled = RWEUIHelper.createBinaryOption(
        layout, "rwe_eventsEnabled", "rwe_events_enabled",
        g_RandomWorldEvents.events.enabled,
        function(val) self:onRWEEventsEnabledChanged(val) end
    )

    -- ── Event Timing ──────────────────────────────────────
    RWEUIHelper.createSubHeader(layout, "rwe_subheader_timing")

    self.frequency = RWEUIHelper.createMultiOption(
        layout, "rwe_frequency", "rwe_frequency",
        RWESettingsIntegration.frequencyOptions,
        g_RandomWorldEvents.events.frequency,
        function(val) self:onRWEFrequencyChanged(val) end
    )

    self.intensity = RWEUIHelper.createMultiOption(
        layout, "rwe_intensity", "rwe_intensity",
        RWESettingsIntegration.intensityOptions,
        g_RandomWorldEvents.events.intensity,
        function(val) self:onRWEIntensityChanged(val) end
    )

    -- Map cooldown value to index
    local coolIdx = 1
    for i, v in ipairs(RWESettingsIntegration.cooldownValues) do
        if v == g_RandomWorldEvents.events.cooldown then coolIdx = i; break end
    end

    self.cooldown = RWEUIHelper.createMultiOption(
        layout, "rwe_cooldown", "rwe_cooldown",
        RWESettingsIntegration.cooldownOptions,
        coolIdx,
        function(val) self:onRWECooldownChanged(val) end
    )

    -- ── Notifications & HUD ───────────────────────────────
    RWEUIHelper.createSubHeader(layout, "rwe_subheader_hud")

    self.notifications = RWEUIHelper.createBinaryOption(
        layout, "rwe_notifications", "rwe_notifications",
        g_RandomWorldEvents.events.showNotifications,
        function(val) self:onRWENotificationsChanged(val) end
    )

    self.warnings = RWEUIHelper.createBinaryOption(
        layout, "rwe_warnings", "rwe_warnings",
        g_RandomWorldEvents.events.showWarnings,
        function(val) self:onRWEWarningsChanged(val) end
    )

    self.showHUD = RWEUIHelper.createBinaryOption(
        layout, "rwe_showHUD", "rwe_show_hud",
        g_RandomWorldEvents.events.showHUD ~= false,
        function(val) self:onRWEShowHUDChanged(val) end
    )

    -- Map HUD scale to index
    local scaleIdx = 3 -- 1.0x default
    for i, v in ipairs(RWESettingsIntegration.hudScaleValues) do
        if math.abs(v - (g_RandomWorldEvents.hudScale or 1.0)) < 0.01 then scaleIdx = i; break end
    end

    self.hudScale = RWEUIHelper.createMultiOption(
        layout, "rwe_hudScale", "rwe_hud_scale",
        RWESettingsIntegration.hudScaleOptions,
        scaleIdx,
        function(val) self:onRWEHudScaleChanged(val) end
    )

    -- ── Event Categories ──────────────────────────────────
    RWEUIHelper.createSubHeader(layout, "rwe_subheader_categories")

    self.economicEvents = RWEUIHelper.createBinaryOption(
        layout, "rwe_economicEvents", "rwe_economic",
        g_RandomWorldEvents.events.economicEvents,
        function(val) self:onRWEEconomicChanged(val) end
    )

    self.vehicleEvents = RWEUIHelper.createBinaryOption(
        layout, "rwe_vehicleEvents", "rwe_vehicle",
        g_RandomWorldEvents.events.vehicleEvents,
        function(val) self:onRWEVehicleChanged(val) end
    )

    self.fieldEvents = RWEUIHelper.createBinaryOption(
        layout, "rwe_fieldEvents", "rwe_field",
        g_RandomWorldEvents.events.fieldEvents,
        function(val) self:onRWEFieldChanged(val) end
    )

    self.wildlifeEvents = RWEUIHelper.createBinaryOption(
        layout, "rwe_wildlifeEvents", "rwe_wildlife",
        g_RandomWorldEvents.events.wildlifeEvents,
        function(val) self:onRWEWildlifeChanged(val) end
    )

    self.specialEvents = RWEUIHelper.createBinaryOption(
        layout, "rwe_specialEvents", "rwe_special",
        g_RandomWorldEvents.events.specialEvents,
        function(val) self:onRWESpecialChanged(val) end
    )

    -- ── Physics Override ──────────────────────────────────
    RWEUIHelper.createSubHeader(layout, "rwe_subheader_physics")

    self.physicsEnabled = RWEUIHelper.createBinaryOption(
        layout, "rwe_physicsEnabled", "rwe_physics_enabled",
        g_RandomWorldEvents.physics.enabled,
        function(val) self:onRWEPhysicsEnabledChanged(val) end
    )

    -- Map physics values to indices
    local gripIdx = 3; local suspIdx = 3
    for i, v in ipairs(RWESettingsIntegration.physicsMultValues) do
        if math.abs(v - (g_RandomWorldEvents.physics.wheelGripMultiplier or 1.0)) < 0.01 then gripIdx = i end
        if math.abs(v - (g_RandomWorldEvents.physics.suspensionStiffness or 1.0)) < 0.01 then suspIdx = i end
    end

    self.wheelGrip = RWEUIHelper.createMultiOption(
        layout, "rwe_wheelGrip", "rwe_wheel_grip",
        RWESettingsIntegration.physicsMultOptions,
        gripIdx,
        function(val) self:onRWEWheelGripChanged(val) end
    )

    self.suspensionStiffness = RWEUIHelper.createMultiOption(
        layout, "rwe_suspensionStiffness", "rwe_suspension",
        RWESettingsIntegration.physicsMultOptions,
        suspIdx,
        function(val) self:onRWESuspensionChanged(val) end
    )

    -- ── Debug ─────────────────────────────────────────────
    RWEUIHelper.createSubHeader(layout, "rwe_subheader_debug")

    self.showPhysicsInfo = RWEUIHelper.createBinaryOption(
        layout, "rwe_showPhysicsInfo", "rwe_physics_info",
        g_RandomWorldEvents.physics.showPhysicsInfo,
        function(val) self:onRWEShowPhysicsInfoChanged(val) end
    )

    self.debugMode = RWEUIHelper.createBinaryOption(
        layout, "rwe_debugMode", "rwe_debug",
        g_RandomWorldEvents.physics.debugMode,
        function(val) self:onRWEDebugChanged(val) end
    )

    self.injected = true
    layout:invalidateLayout()
    Logging.info("[RWE] Settings UI injected successfully")
end

-- =========================================================
-- Callbacks
-- =========================================================

local function applyEventSetting(key, value)
    if g_RandomWorldEvents then
        g_RandomWorldEvents.events[key] = value
        g_RandomWorldEvents:saveSettings()
        Logging.info("[RWE] Event setting: " .. tostring(key) .. " = " .. tostring(value))
    end
end

local function applyPhysicsSetting(key, value)
    if g_RandomWorldEvents then
        g_RandomWorldEvents.physics[key] = value
        g_RandomWorldEvents:saveSettings()
        Logging.info("[RWE] Physics setting: " .. tostring(key) .. " = " .. tostring(value))
    end
end

function RWESettingsIntegration:onRWEEventsEnabledChanged(state) applyEventSetting("enabled", state) end
function RWESettingsIntegration:onRWEFrequencyChanged(state) applyEventSetting("frequency", state) end
function RWESettingsIntegration:onRWEIntensityChanged(state) applyEventSetting("intensity", state) end
function RWESettingsIntegration:onRWECooldownChanged(state)
    applyEventSetting("cooldown", RWESettingsIntegration.cooldownValues[state] or 30)
end
function RWESettingsIntegration:onRWENotificationsChanged(state) applyEventSetting("showNotifications", state) end
function RWESettingsIntegration:onRWEWarningsChanged(state) applyEventSetting("showWarnings", state) end
function RWESettingsIntegration:onRWEShowHUDChanged(state) applyEventSetting("showHUD", state) end
function RWESettingsIntegration:onRWEHudScaleChanged(state)
    local scale = RWESettingsIntegration.hudScaleValues[state] or 1.0
    if g_RandomWorldEvents then
        g_RandomWorldEvents.hudScale = scale
        if g_RandomWorldEvents.eventHUD then g_RandomWorldEvents.eventHUD.scale = scale end
        g_RandomWorldEvents:saveSettings()
        Logging.info("[RWE] hudScale = " .. tostring(scale))
    end
end
function RWESettingsIntegration:onRWEEconomicChanged(state) applyEventSetting("economicEvents", state) end
function RWESettingsIntegration:onRWEVehicleChanged(state) applyEventSetting("vehicleEvents", state) end
function RWESettingsIntegration:onRWEFieldChanged(state) applyEventSetting("fieldEvents", state) end
function RWESettingsIntegration:onRWEWildlifeChanged(state) applyEventSetting("wildlifeEvents", state) end
function RWESettingsIntegration:onRWESpecialChanged(state) applyEventSetting("specialEvents", state) end
function RWESettingsIntegration:onRWEPhysicsEnabledChanged(state) applyPhysicsSetting("enabled", state) end
function RWESettingsIntegration:onRWEWheelGripChanged(state)
    applyPhysicsSetting("wheelGripMultiplier", RWESettingsIntegration.physicsMultValues[state] or 1.0)
end
function RWESettingsIntegration:onRWESuspensionChanged(state)
    applyPhysicsSetting("suspensionStiffness", RWESettingsIntegration.physicsMultValues[state] or 1.0)
end
function RWESettingsIntegration:onRWEShowPhysicsInfoChanged(state) applyPhysicsSetting("showPhysicsInfo", state) end
function RWESettingsIntegration:onRWEDebugChanged(state) applyPhysicsSetting("debugMode", state) end

-- =========================================================
-- Initialize hooks (runs at file load time)
-- =========================================================

local function initHooks()
    if not InGameMenuSettingsFrame then
        Logging.warning("[RWE] InGameMenuSettingsFrame not found at file load time.")
        return
    end

    InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(
        InGameMenuSettingsFrame.onFrameOpen,
        function(frame)
            local ok, err = pcall(function() RWESettingsIntegration:inject(frame) end)
            if not ok then
                Logging.error("[RWE] Settings injection failed: " .. tostring(err))
            end
        end
    )
    
    Logging.info("[RWE] Settings UI hooks installed")
end

initHooks()

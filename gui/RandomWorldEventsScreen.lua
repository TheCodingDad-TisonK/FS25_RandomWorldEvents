-- =========================================================
-- Random World Events (version 2.0.0.1) - FS25
-- Settings dialog — extends MessageDialog (FS25 mod pattern)
-- Author: TisonK
-- =========================================================

---@class RandomWorldEventsScreen
RandomWorldEventsScreen = {}
local RandomWorldEventsScreen_mt = Class(RandomWorldEventsScreen, MessageDialog)

function RandomWorldEventsScreen.new(target, customMt)
    local self = MessageDialog.new(target, customMt or RandomWorldEventsScreen_mt)
    return self
end

-- Called by FS25 after the XML element tree is built.
function RandomWorldEventsScreen:onCreate()
    -- Event settings
    self.boxLayout          = self:getDescendantByName("boxLayout")
    self.eventsEnabled      = self:getDescendantByName("eventsEnabled")
    self.eventsFrequency    = self:getDescendantByName("eventsFrequency")
    self.eventsIntensity    = self:getDescendantByName("eventsIntensity")
    self.eventsCooldown     = self:getDescendantByName("eventsCooldown")
    self.showNotifications  = self:getDescendantByName("showNotifications")
    self.showWarnings       = self:getDescendantByName("showWarnings")
    self.weatherEvents      = self:getDescendantByName("weatherEvents")
    self.economicEvents     = self:getDescendantByName("economicEvents")
    self.vehicleEvents      = self:getDescendantByName("vehicleEvents")
    self.fieldEvents        = self:getDescendantByName("fieldEvents")
    self.wildlifeEvents     = self:getDescendantByName("wildlifeEvents")
    self.specialEvents      = self:getDescendantByName("specialEvents")
    self.triggerEventButton = self:getDescendantByName("triggerEventButton")
    -- Physics settings
    self.physicsEnabled      = self:getDescendantByName("physicsEnabled")
    self.wheelGripMultiplier = self:getDescendantByName("wheelGripMultiplier")
    self.articulationDamping = self:getDescendantByName("articulationDamping")
    self.comStrength         = self:getDescendantByName("comStrength")
    self.suspensionStiffness = self:getDescendantByName("suspensionStiffness")
    self.showPhysicsInfo     = self:getDescendantByName("showPhysicsInfo")
    self.debugMode           = self:getDescendantByName("debugMode")
end

function RandomWorldEventsScreen:onOpen()
    RandomWorldEventsScreen:superClass().onOpen(self)
    self:updateDisplay()
    if self.boxLayout then
        self.boxLayout:invalidateLayout()
    end
    Logging.info("[RWE] Settings screen opened")
end

-- Custom close name avoids conflicts with MessageDialog's internal onClose lifecycle.
function RandomWorldEventsScreen:onRWEClose()
    RandomWorldEventsScreen:superClass().onClose(self)
    Logging.info("[RWE] Settings screen closed")
end

function RandomWorldEventsScreen:onCloseClick()
    self:close()
end

function RandomWorldEventsScreen:updateDisplay()
    if not g_RandomWorldEvents then return end
    local ev = g_RandomWorldEvents.events
    local ph = g_RandomWorldEvents.physics

    if self.eventsEnabled     then self.eventsEnabled:setIsChecked(ev.enabled) end
    if self.showNotifications then self.showNotifications:setIsChecked(ev.showNotifications) end
    if self.showWarnings      then self.showWarnings:setIsChecked(ev.showWarnings) end
    if self.weatherEvents     then self.weatherEvents:setIsChecked(ev.weatherEvents) end
    if self.economicEvents    then self.economicEvents:setIsChecked(ev.economicEvents) end
    if self.vehicleEvents     then self.vehicleEvents:setIsChecked(ev.vehicleEvents) end
    if self.fieldEvents       then self.fieldEvents:setIsChecked(ev.fieldEvents) end
    if self.wildlifeEvents    then self.wildlifeEvents:setIsChecked(ev.wildlifeEvents) end
    if self.specialEvents     then self.specialEvents:setIsChecked(ev.specialEvents) end

    if self.eventsFrequency then self.eventsFrequency:setText(string.format('%d', ev.frequency)) end
    if self.eventsIntensity then self.eventsIntensity:setText(string.format('%d', ev.intensity)) end
    if self.eventsCooldown  then self.eventsCooldown:setText(string.format('%d', ev.cooldown))  end

    if self.physicsEnabled      then self.physicsEnabled:setIsChecked(ph.enabled) end
    if self.showPhysicsInfo     then self.showPhysicsInfo:setIsChecked(ph.showPhysicsInfo) end
    if self.debugMode           then self.debugMode:setIsChecked(ph.debugMode) end

    if self.wheelGripMultiplier then self.wheelGripMultiplier:setText(string.format('%.2f', ph.wheelGripMultiplier)) end
    if self.articulationDamping then self.articulationDamping:setText(string.format('%.2f', ph.articulationDamping)) end
    if self.comStrength         then self.comStrength:setText(string.format('%.2f', ph.comStrength)) end
    if self.suspensionStiffness then self.suspensionStiffness:setText(string.format('%.2f', ph.suspensionStiffness)) end
end

-- onClick for all checkedOption toggles
---@param state number
---@param element CheckedOptionElement
function RandomWorldEventsScreen:onCheckClick(state, element)
    if not g_RandomWorldEvents then return end
    local checked = (state == CheckedOptionElement.STATE_CHECKED)
    local id = element.id or element.name
    if not id then return end

    local ev = g_RandomWorldEvents.events
    local ph = g_RandomWorldEvents.physics

    if     id == "eventsEnabled"     then ev.enabled           = checked
    elseif id == "showNotifications" then ev.showNotifications = checked
    elseif id == "showWarnings"      then ev.showWarnings      = checked
    elseif id == "weatherEvents"     then ev.weatherEvents     = checked
    elseif id == "economicEvents"    then ev.economicEvents    = checked
    elseif id == "vehicleEvents"     then ev.vehicleEvents     = checked
    elseif id == "fieldEvents"       then ev.fieldEvents       = checked
    elseif id == "wildlifeEvents"    then ev.wildlifeEvents    = checked
    elseif id == "specialEvents"     then ev.specialEvents     = checked
    elseif id == "physicsEnabled"    then ph.enabled           = checked
    elseif id == "showPhysicsInfo"   then ph.showPhysicsInfo   = checked
    elseif id == "debugMode"         then ph.debugMode         = checked
    end

    g_RandomWorldEvents:saveSettings()
    Logging.info("[RWE] Toggle: " .. id .. " = " .. tostring(checked))
end

-- onEnterPressed for numeric text inputs
---@param element TextInputElement
function RandomWorldEventsScreen:onEnterPressedTextInput(element)
    if not g_RandomWorldEvents then return end
    local id    = element.id or element.name
    local value = tonumber(element.text)

    if id == 'eventsFrequency' then
        value = math.max(1, math.min(10, value or g_RandomWorldEvents.events.frequency))
        g_RandomWorldEvents.events.frequency = value
        element:setText(string.format('%d', value))
    elseif id == 'eventsIntensity' then
        value = math.max(1, math.min(5, value or g_RandomWorldEvents.events.intensity))
        g_RandomWorldEvents.events.intensity = value
        element:setText(string.format('%d', value))
    elseif id == 'eventsCooldown' then
        value = math.max(1, math.min(240, value or g_RandomWorldEvents.events.cooldown))
        g_RandomWorldEvents.events.cooldown = value
        element:setText(string.format('%d', value))
    else
        local current = g_RandomWorldEvents.physics[id] or 1.0
        value = math.max(0.1, math.min(5.0, value or current))
        if id then g_RandomWorldEvents.physics[id] = value end
        element:setText(string.format('%.2f', value))
    end

    g_RandomWorldEvents:saveSettings()
    Logging.info("[RWE] Input: " .. tostring(id) .. " = " .. tostring(value))
end

-- onClick for the Trigger Event button
function RandomWorldEventsScreen:onTriggerEventClick()
    if g_RandomWorldEvents and g_RandomWorldEvents.triggerRandomEvent then
        g_RandomWorldEvents:triggerRandomEvent()
        Logging.info("[RWE] Manual event triggered from GUI")
    end
end

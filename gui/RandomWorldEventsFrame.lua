-- =========================================================
-- Random World Events (version 2.0.0.1) - FS25
-- Events / Settings frame
-- Author: TisonK
-- =========================================================

---@class RandomWorldEventsFrame
RandomWorldEventsFrame = {}
local RandomWorldEventsFrame_mt = Class(RandomWorldEventsFrame, TabbedMenuFrameElement)

function RandomWorldEventsFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or RandomWorldEventsFrame_mt)
    return self
end

-- Called by RandomWorldEventsScreen:onGuiSetupFinished after pages are wired.
function RandomWorldEventsFrame:initialize()
    self.backButtonInfo = { inputAction = InputAction.MENU_BACK }

    -- FS25: registerControls not available on TabbedMenuFrameElement; wire by element name
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
end

function RandomWorldEventsFrame:onFrameOpen()
    RandomWorldEventsFrame:superClass().onFrameOpen(self)

    if not self.boxLayout then
        Logging.warning("[RWE] EventsFrame: boxLayout not found, skipping open setup")
        return
    end

    self:updateDisplay()
    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        if self.setSoundSuppressed then self:setSoundSuppressed(true) end
        FocusManager:setFocus(self.boxLayout)
        if self.setSoundSuppressed then self:setSoundSuppressed(false) end
    end
end

function RandomWorldEventsFrame:updateDisplay()
    if not g_RandomWorldEvents then return end
    local ev = g_RandomWorldEvents.events

    if self.eventsEnabled      then self.eventsEnabled:setIsChecked(ev.enabled) end
    if self.showNotifications  then self.showNotifications:setIsChecked(ev.showNotifications) end
    if self.showWarnings       then self.showWarnings:setIsChecked(ev.showWarnings) end
    if self.weatherEvents      then self.weatherEvents:setIsChecked(ev.weatherEvents) end
    if self.economicEvents     then self.economicEvents:setIsChecked(ev.economicEvents) end
    if self.vehicleEvents      then self.vehicleEvents:setIsChecked(ev.vehicleEvents) end
    if self.fieldEvents        then self.fieldEvents:setIsChecked(ev.fieldEvents) end
    if self.wildlifeEvents     then self.wildlifeEvents:setIsChecked(ev.wildlifeEvents) end
    if self.specialEvents      then self.specialEvents:setIsChecked(ev.specialEvents) end

    if self.eventsFrequency then self.eventsFrequency:setText(string.format('%d', ev.frequency)) end
    if self.eventsIntensity then self.eventsIntensity:setText(string.format('%d', ev.intensity)) end
    if self.eventsCooldown  then self.eventsCooldown:setText(string.format('%d', ev.cooldown))  end
end

-- onClick callback for all checkedOption toggles
---@param state number
---@param element CheckedOptionElement
function RandomWorldEventsFrame:onCheckClick(state, element)
    if not g_RandomWorldEvents then return end

    local checked = (state == CheckedOptionElement.STATE_CHECKED)
    local id = element.id or element.name

    if id == "eventsEnabled" then
        g_RandomWorldEvents.events.enabled = checked
    elseif id then
        g_RandomWorldEvents.events[id] = checked
    end

    g_RandomWorldEvents:saveSettings()
    Logging.info("[RWE] Event toggle: " .. tostring(id) .. " = " .. tostring(checked))
end

-- onEnterPressed callback for numeric text inputs
---@param element TextInputElement
function RandomWorldEventsFrame:onEnterPressedTextInput(element)
    if not g_RandomWorldEvents then return end

    local value = tonumber(element.text)
    if value == nil then return end

    local id = element.id or element.name

    if id == 'eventsFrequency' then
        value = math.max(1, math.min(10, value))
        g_RandomWorldEvents.events.frequency = value
    elseif id == 'eventsIntensity' then
        value = math.max(1, math.min(5, value))
        g_RandomWorldEvents.events.intensity = value
    elseif id == 'eventsCooldown' then
        value = math.max(1, math.min(240, value))
        g_RandomWorldEvents.events.cooldown = value
    end

    element:setText(string.format('%d', value))
    g_RandomWorldEvents:saveSettings()
    Logging.info("[RWE] Event value: " .. tostring(id) .. " = " .. tostring(value))
end

-- onClick callback for the Trigger Event button
function RandomWorldEventsFrame:onTriggerEventClick()
    if g_RandomWorldEvents and g_RandomWorldEvents.triggerRandomEvent then
        g_RandomWorldEvents:triggerRandomEvent()
        Logging.info("[RWE] Manual event triggered from GUI")
    end
end

-- =========================================================
-- Random World Events (version 2.0.0.0) - FS25
-- =========================================================
-- Events frame for FS25
-- =========================================================
-- Author: TisonK
-- =========================================================

---@class RandomWorldEventsFrame
RandomWorldEventsFrame = {}

local RandomWorldEventsFrame_mt = Class(RandomWorldEventsFrame, TabbedMenuFrameElement)

RandomWorldEventsFrame.CONTROLS = {
    'eventsEnabled',
    'eventsFrequency',
    'eventsIntensity',
    'eventsCooldown',
    'showNotifications',
    'showWarnings',
    'weatherEvents',
    'economicEvents',
    'vehicleEvents',
    'fieldEvents',
    'wildlifeEvents',
    'specialEvents',
    'triggerEventButtonWrapper',
    'boxLayout'
}

function RandomWorldEventsFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or RandomWorldEventsFrame_mt)
    self:registerControls(RandomWorldEventsFrame.CONTROLS)
    return self
end

function RandomWorldEventsFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function RandomWorldEventsFrame:onFrameOpen()
    RandomWorldEventsFrame:superClass().onFrameOpen(self)
    self:updateRandomEvents()
    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function RandomWorldEventsFrame:updateRandomEvents()
    if not g_RandomWorldEvents then return end
    
    self.eventsEnabled:setIsChecked(g_RandomWorldEvents.events.enabled)
    self.showNotifications:setIsChecked(g_RandomWorldEvents.events.showNotifications)
    self.showWarnings:setIsChecked(g_RandomWorldEvents.events.showWarnings)
    self.weatherEvents:setIsChecked(g_RandomWorldEvents.events.weatherEvents)
    self.economicEvents:setIsChecked(g_RandomWorldEvents.events.economicEvents)
    self.vehicleEvents:setIsChecked(g_RandomWorldEvents.events.vehicleEvents)
    self.fieldEvents:setIsChecked(g_RandomWorldEvents.events.fieldEvents)
    self.wildlifeEvents:setIsChecked(g_RandomWorldEvents.events.wildlifeEvents)
    self.specialEvents:setIsChecked(g_RandomWorldEvents.events.specialEvents)

    self:setElementText(self.eventsFrequency, g_RandomWorldEvents.events.frequency)
    self:setElementText(self.eventsIntensity, g_RandomWorldEvents.events.intensity)
    self:setElementText(self.eventsCooldown, g_RandomWorldEvents.events.cooldown)
end

function RandomWorldEventsFrame:setElementText(element, value)
    element:setText(string.format('%.0f', value))
end

---@param state number
---@param element CheckedOptionElement
function RandomWorldEventsFrame:onCheckClick(state, element)
    if not g_RandomWorldEvents then return end
    
    local value = state == CheckedOptionElement.STATE_CHECKED

    if element.id == "eventsEnabled" then
        g_RandomWorldEvents.events.enabled = value
    else
        g_RandomWorldEvents.events[element.id] = value
    end

    if g_RandomWorldEvents.saveSettings then
        g_RandomWorldEvents:saveSettings()
    end
    
    Logging.info("[RWE] Event setting changed: " .. element.id .. " = " .. tostring(value))
end

---@param element TextInputElement
function RandomWorldEventsFrame:onEnterPressedTextInput(element)
    if not g_RandomWorldEvents then return end
    
    local value = tonumber(element.text)
    if value == nil then return end

    if element.id == 'eventsFrequency' then
        value = math.max(1, math.min(10, value))
        g_RandomWorldEvents.events.frequency = value

    elseif element.id == 'eventsIntensity' then
        value = math.max(1, math.min(5, value))
        g_RandomWorldEvents.events.intensity = value

    elseif element.id == 'eventsCooldown' then
        value = math.max(1, math.min(240, value))
        g_RandomWorldEvents.events.cooldown = value
    end

    if g_RandomWorldEvents.saveSettings then
        g_RandomWorldEvents:saveSettings()
    end
    
    self:setElementText(element, value)
    Logging.info("[RWE] Event value changed: " .. element.id .. " = " .. tostring(value))
end

function RandomWorldEventsFrame:onTriggerEventClick()
    if g_RandomWorldEvents and g_RandomWorldEvents.triggerRandomEvent then
        g_RandomWorldEvents:triggerRandomEvent()
        Logging.info("[RWE] Manual event triggered from GUI")
    end
end
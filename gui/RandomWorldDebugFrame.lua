-- =========================================================
-- Random World Events (version 2.0.0.0) - FS25
-- =========================================================
-- Debug frame for FS25
-- =========================================================
-- Author: TisonK
-- =========================================================

---@class RandomWorldEventsDebugFrame
RandomWorldEventsDebugFrame = {}

local RandomWorldEventsDebugFrame_mt = Class(RandomWorldEventsDebugFrame, TabbedMenuFrameElement)

RandomWorldEventsDebugFrame.CONTROLS = {
    'physicsEnabled',
    'wheelGripMultiplier',
    'articulationDamping',
    'comStrength',
    'suspensionStiffness',
    'showPhysicsInfo',
    'debugMode',
    'boxLayout'
}

function RandomWorldEventsDebugFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or RandomWorldEventsDebugFrame_mt)
    self:registerControls(RandomWorldEventsDebugFrame.CONTROLS)
    return self
end

function RandomWorldEventsDebugFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function RandomWorldEventsDebugFrame:onFrameOpen()
    RandomWorldEventsDebugFrame:superClass().onFrameOpen(self)
    self:updateRandomEvents()
    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function RandomWorldEventsDebugFrame:updateRandomEvents()
    if not g_RandomWorldEvents then return end
    
    self.physicsEnabled:setIsChecked(g_RandomWorldEvents.physics.enabled)
    self.showPhysicsInfo:setIsChecked(g_RandomWorldEvents.physics.showPhysicsInfo)
    self.debugMode:setIsChecked(g_RandomWorldEvents.physics.debugMode)

    self:setElementText(self.wheelGripMultiplier, g_RandomWorldEvents.physics.wheelGripMultiplier)
    self:setElementText(self.articulationDamping, g_RandomWorldEvents.physics.articulationDamping)
    self:setElementText(self.comStrength, g_RandomWorldEvents.physics.comStrength)
    self:setElementText(self.suspensionStiffness, g_RandomWorldEvents.physics.suspensionStiffness)
end

function RandomWorldEventsDebugFrame:setElementText(element, value)
    element:setText(string.format('%.2f', value))
end

---@param state number
---@param element CheckedOptionElement
function RandomWorldEventsDebugFrame:onCheckClick(state, element)
    if not g_RandomWorldEvents then return end
    
    local value = state == CheckedOptionElement.STATE_CHECKED
    g_RandomWorldEvents.physics[element.id] = value
    
    if g_RandomWorldEvents.saveSettings then
        g_RandomWorldEvents:saveSettings()
    end
    
    Logging.info("[RWE] Physics setting changed: " .. element.id .. " = " .. tostring(value))
end

---@param element TextInputElement
function RandomWorldEventsDebugFrame:onEnterPressedTextInput(element)
    if not g_RandomWorldEvents then return end
    
    local value = tonumber(element.text)
    if value ~= nil then
        if value < 0.1 then value = 0.1 end
        if value > 5.0 then value = 5.0 end
        g_RandomWorldEvents.physics[element.id] = value
    end

    self:setElementText(element, g_RandomWorldEvents.physics[element.id])
    
    if g_RandomWorldEvents.saveSettings then
        g_RandomWorldEvents:saveSettings()
    end
    
    Logging.info("[RWE] Physics value changed: " .. element.id .. " = " .. tostring(value))
end
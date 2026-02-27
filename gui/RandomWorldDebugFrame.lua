-- =========================================================
-- Random World Events (version 2.0.0.1) - FS25
-- Physics / Debug frame
-- Author: TisonK
-- =========================================================

---@class RandomWorldEventsDebugFrame
RandomWorldEventsDebugFrame = {}
local RandomWorldEventsDebugFrame_mt = Class(RandomWorldEventsDebugFrame, TabbedMenuFrameElement)

function RandomWorldEventsDebugFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or RandomWorldEventsDebugFrame_mt)
    return self
end

-- Called by RandomWorldEventsScreen:onGuiSetupFinished after pages are wired.
function RandomWorldEventsDebugFrame:initialize()
    self.backButtonInfo = { inputAction = InputAction.MENU_BACK }

    -- FS25: registerControls not available on TabbedMenuFrameElement; wire by element name
    self.boxLayout           = self:getDescendantByName("boxLayout")
    self.physicsEnabled      = self:getDescendantByName("physicsEnabled")
    self.wheelGripMultiplier = self:getDescendantByName("wheelGripMultiplier")
    self.articulationDamping = self:getDescendantByName("articulationDamping")
    self.comStrength         = self:getDescendantByName("comStrength")
    self.suspensionStiffness = self:getDescendantByName("suspensionStiffness")
    self.showPhysicsInfo     = self:getDescendantByName("showPhysicsInfo")
    self.debugMode           = self:getDescendantByName("debugMode")
end

function RandomWorldEventsDebugFrame:onFrameOpen()
    RandomWorldEventsDebugFrame:superClass().onFrameOpen(self)

    if not self.boxLayout then
        Logging.warning("[RWE] DebugFrame: boxLayout not found, skipping open setup")
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

function RandomWorldEventsDebugFrame:updateDisplay()
    if not g_RandomWorldEvents then return end
    local ph = g_RandomWorldEvents.physics

    if self.physicsEnabled  then self.physicsEnabled:setIsChecked(ph.enabled) end
    if self.showPhysicsInfo then self.showPhysicsInfo:setIsChecked(ph.showPhysicsInfo) end
    if self.debugMode       then self.debugMode:setIsChecked(ph.debugMode) end

    if self.wheelGripMultiplier  then self.wheelGripMultiplier:setText(string.format('%.2f', ph.wheelGripMultiplier))   end
    if self.articulationDamping  then self.articulationDamping:setText(string.format('%.2f', ph.articulationDamping))   end
    if self.comStrength          then self.comStrength:setText(string.format('%.2f', ph.comStrength))                   end
    if self.suspensionStiffness  then self.suspensionStiffness:setText(string.format('%.2f', ph.suspensionStiffness))   end
end

-- onClick callback for all checkedOption toggles
---@param state number
---@param element CheckedOptionElement
function RandomWorldEventsDebugFrame:onCheckClick(state, element)
    if not g_RandomWorldEvents then return end

    local checked = (state == CheckedOptionElement.STATE_CHECKED)
    local id = element.id or element.name

    if id then
        g_RandomWorldEvents.physics[id] = checked
    end

    g_RandomWorldEvents:saveSettings()
    Logging.info("[RWE] Physics toggle: " .. tostring(id) .. " = " .. tostring(checked))
end

-- onEnterPressed callback for numeric text inputs
---@param element TextInputElement
function RandomWorldEventsDebugFrame:onEnterPressedTextInput(element)
    if not g_RandomWorldEvents then return end

    local id = element.id or element.name
    local value = tonumber(element.text)

    if value ~= nil then
        value = math.max(0.1, math.min(5.0, value))
        g_RandomWorldEvents.physics[id] = value
    else
        value = g_RandomWorldEvents.physics[id]
    end

    element:setText(string.format('%.2f', value))
    g_RandomWorldEvents:saveSettings()
    Logging.info("[RWE] Physics value: " .. tostring(id) .. " = " .. tostring(value))
end

-- =========================================================
-- Random World Events (version 2.0.0.0) - FS25
-- =========================================================
-- Main screen for FS25
-- =========================================================
-- Author: TisonK
-- =========================================================

---@class RandomWorldEventsScreen
RandomWorldEventsScreen = {}
local RandomWorldEventsScreen_mt = Class(RandomWorldEventsScreen, TabbedMenuWithDetails)

RandomWorldEventsScreen.CONTROLS = {
    'pageOptionsEvents',
    'pageOptionsDebug',
}

function RandomWorldEventsScreen.new(target, customMt, messageCenter, l10n, inputManager)
    local self = TabbedMenuWithDetails.new(target, customMt or RandomWorldEventsScreen_mt, messageCenter, l10n, inputManager)
    self:registerControls(RandomWorldEventsScreen.CONTROLS)
    return self
end

function RandomWorldEventsScreen:onGuiSetupFinished()
    RandomWorldEventsScreen:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
    
    if self.pageOptionsEvents then
        self.pageOptionsEvents:initialize()
    end
    
    if self.pageOptionsDebug then
        self.pageOptionsDebug:initialize()
    end

    self:setupPages()
    self:setupMenuButtonInfo()
end

function RandomWorldEventsScreen:setupPages()
    local pages = {
        {
            self.pageOptionsEvents,
            'events.dds'    -- Events/settings tab
        },
        {
            self.pageOptionsDebug,
            'settings.dds'  -- Physics/debug tab
        },
    }

    for i, _page in ipairs(pages) do
        local page, icon = unpack(_page)
        if page then
            self:registerPage(page, i)
            local iconPath = g_RandomWorldEvents and g_RandomWorldEvents.modDirectory .. 'icons/' .. icon or icon
            self:addPageTab(page, iconPath)
        end
    end
end

function RandomWorldEventsScreen:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback
    self.defaultMenuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK,
            text = self.l10n:getText("button_back"),
            callback = onButtonBackFunction
        }
    }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
    }
end

function RandomWorldEventsScreen:exitMenu()
    self:changeScreen()
end

function RandomWorldEventsScreen:onButtonBack()
    self:exitMenu()
end

function RandomWorldEventsScreen:onOpen()
    RandomWorldEventsScreen:superClass().onOpen(self)
    Logging.info("[RWE] Settings screen opened")
end

function RandomWorldEventsScreen:onClose()
    RandomWorldEventsScreen:superClass().onClose(self)
    Logging.info("[RWE] Settings screen closed")
end
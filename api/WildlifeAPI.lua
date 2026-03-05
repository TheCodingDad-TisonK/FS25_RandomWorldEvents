-- =========================================================
-- RWEWildlifeAPI v1.0.0
-- Public subsystem API for the Wildlife event category.
-- Third-party mods consume this table to register custom
-- livestock/wildlife events and observe category activity.
-- =========================================================
-- Author: TisonK  |  Part of FS25_RandomWorldEvents
-- =========================================================
--
-- USAGE (third-party mod):
--   if RWEWildlifeAPI and RWEWildlifeAPI.registerAnimalEffect then
--     RWEWildlifeAPI:registerAnimalEffect(
--       "myMod_wolf_sighting",
--       function(intensity)  -- onStart
--         if g_RandomWorldEvents then
--           g_RandomWorldEvents.EVENT_STATE.animalProductMalus = 0.08 * intensity
--         end
--         return "Wolf spotted near the farm! Livestock stressed."
--       end,
--       function()  -- onEnd (optional)
--         if g_RandomWorldEvents then
--           g_RandomWorldEvents.EVENT_STATE.animalProductMalus = nil
--         end
--       end
--     )
--   end
-- =========================================================

---@class RWEWildlifeAPI
RWEWildlifeAPI = {
    _VERSION  = "1.0.0",
    _CATEGORY = "wildlife",

    _startCallbacks = {},
    _endCallbacks   = {},
    _pendingTicks   = {},
    _tickCounter    = 0,
}

-- =====================
-- CORE API SURFACE
-- =====================

--- Register a new wildlife event.
--- def fields:
---   name         (string)   unique event identifier
---   func         (function) onStart handler: function(intensity) → string|nil
---   minIntensity (number)   minimum global intensity required (1-5)
---   weight       (number?)  random selection weight (default 1)
---   duration     (table?)   {min=N, max=M} in minutes (default {min=15,max=60})
---   canTrigger   (function?) guard; defaults to mission-exists check
---   onEnd        (function?) cleanup handler → string|nil
---@param def table
---@return boolean
function RWEWildlifeAPI:registerEvent(def)
    if type(def) ~= "table" then
        Logging.warning("[RWEWildlifeAPI] registerEvent: def must be a table")
        return false
    end
    if not def.name or not def.func then
        Logging.warning("[RWEWildlifeAPI] registerEvent: def.name and def.func are required")
        return false
    end
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[RWEWildlifeAPI] registerEvent: core not ready for event '" .. tostring(def.name)
            .. "'. Call from onMissionLoaded, not at file scope.")
        return false
    end

    local api      = self
    local userFunc = def.func
    local userEnd  = def.onEnd

    local coreDef = {
        name         = def.name,
        category     = self._CATEGORY,
        weight       = def.weight or 1,
        duration     = def.duration or { min = 15, max = 60 },
        minIntensity = def.minIntensity or 1,

        -- Require a loaded mission; skip livestock-only events if no husbandries exist
        canTrigger = def.canTrigger or function()
            if g_currentMission == nil then return false end
            if g_currentMission.animalSystem then
                local h = g_currentMission.animalSystem:getHusbandries()
                -- Allow the event if husbandries exist OR if not explicitly livestock-only
                return h == nil or #h > 0 or not def.requiresAnimals
            end
            return true
        end,

        onStart = function(intensity)
            local msg = userFunc(intensity)
            for _, cb in ipairs(api._startCallbacks) do
                pcall(cb, def, intensity)
            end
            return msg
        end,

        onEnd = function()
            local msg = userEnd and userEnd() or "Wildlife event ended"
            for _, cb in ipairs(api._endCallbacks) do
                pcall(cb, def)
            end
            return msg
        end,
    }

    g_RandomWorldEvents:registerEvent(coreDef)
    return true
end

--- Returns a shallow copy of all registered wildlife events.
---@return table[]
function RWEWildlifeAPI:getEventList()
    if not g_RandomWorldEvents then return {} end
    local result = {}
    for _, event in pairs(g_RandomWorldEvents.EVENTS) do
        if event.category == self._CATEGORY then
            local copy = {}
            for k, v in pairs(event) do copy[k] = v end
            table.insert(result, copy)
        end
    end
    return result
end

--- Manually fire a named wildlife event at the given intensity.
---@param name string
---@param intensity number  1-5
---@return string
function RWEWildlifeAPI:triggerEvent(name, intensity)
    if not g_RandomWorldEvents then
        return "[RWEWildlifeAPI] Core not available"
    end
    if g_RandomWorldEvents.EVENT_STATE.activeEvent ~= nil then
        return "[RWEWildlifeAPI] Another event is already active: "
            .. tostring(g_RandomWorldEvents.EVENT_STATE.activeEvent)
    end

    local event = g_RandomWorldEvents.EVENTS[name]
    if not event then
        return "[RWEWildlifeAPI] Event not found: " .. tostring(name)
    end
    if event.category ~= self._CATEGORY then
        return "[RWEWildlifeAPI] Event '" .. name .. "' is not a wildlife event"
    end

    local safeIntensity = math.max(1, math.min(5, math.floor(intensity or 1)))

    g_RandomWorldEvents.EVENT_STATE.activeEvent    = name
    g_RandomWorldEvents.EVENT_STATE.eventStartTime = g_currentMission and g_currentMission.time or 0

    local duration = 0
    if type(event.duration) == "table" then
        duration = math.random(event.duration.min, event.duration.max) * 60000
    end
    g_RandomWorldEvents.EVENT_STATE.eventDuration = duration

    local msg = event.onStart(safeIntensity)
    if msg and g_RandomWorldEvents.events.showNotifications and g_currentMission then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, msg)
    end

    Logging.info(string.format("[RWEWildlifeAPI] Triggered event '%s' at intensity %d", name, safeIntensity))
    return msg or ("Triggered: " .. name)
end

--- Returns true while any wildlife event is active.
---@return boolean
function RWEWildlifeAPI:isEventActive()
    if not g_RandomWorldEvents then return false end
    local id = g_RandomWorldEvents.EVENT_STATE.activeEvent
    if not id then return false end
    local event = g_RandomWorldEvents.EVENTS[id]
    return event ~= nil and event.category == self._CATEGORY
end

--- Returns the active wildlife event definition, or nil if none is active.
---@return table|nil
function RWEWildlifeAPI:getActiveEvent()
    if not g_RandomWorldEvents then return nil end
    local id = g_RandomWorldEvents.EVENT_STATE.activeEvent
    if not id then return nil end
    local event = g_RandomWorldEvents.EVENTS[id]
    if event and event.category == self._CATEGORY then
        return event
    end
    return nil
end

--- Add a per-tick callback (fires ~every 60 in-game seconds while an event is active).
--- If the core is already available the handler is registered immediately.
--- If called before the core is ready the handler is buffered and flushed on init.
---@param fn function(rweInstance)
function RWEWildlifeAPI:registerTickHandler(fn)
    if type(fn) ~= "function" then return end
    self._tickCounter = self._tickCounter + 1
    local key = "RWEWildlifeAPI_tick_" .. self._tickCounter
    if g_RandomWorldEvents and g_RandomWorldEvents.registerTickHandler then
        g_RandomWorldEvents:registerTickHandler(key, fn)
    else
        table.insert(self._pendingTicks, { key = key, fn = fn })
    end
end

--- Returns the API semantic version string.
---@return string
function RWEWildlifeAPI:getVersion()
    return self._VERSION
end

--- Subscribe to event-start notifications for wildlife events registered via this API.
---@param cb function(eventDef, intensity)
function RWEWildlifeAPI:onEventStart(cb)
    if type(cb) == "function" then
        table.insert(self._startCallbacks, cb)
    end
end

--- Subscribe to event-end notifications for wildlife events registered via this API.
---@param cb function(eventDef)
function RWEWildlifeAPI:onEventEnd(cb)
    if type(cb) == "function" then
        table.insert(self._endCallbacks, cb)
    end
end

-- =====================
-- CATEGORY-SPECIFIC: ANIMAL EFFECT REGISTRATION
-- =====================

--- Convenience wrapper: register a named livestock/wildlife effect as a wildlife event.
--- onStart: function(intensity) → string|nil   (event start handler)
--- onEnd:   function() → string|nil            (optional cleanup handler)
--- The event is assigned minIntensity=1 and the standard wildlife canTrigger guard.
---@param name    string
---@param onStart function(intensity) → string|nil
---@param onEnd   function|nil
---@return boolean
function RWEWildlifeAPI:registerAnimalEffect(name, onStart, onEnd)
    if type(name) ~= "string" or type(onStart) ~= "function" then
        Logging.warning("[RWEWildlifeAPI] registerAnimalEffect: name (string) and onStart (function) required")
        return false
    end

    return self:registerEvent({
        name         = name,
        minIntensity = 1,
        func         = onStart,
        onEnd        = onEnd,
        requiresAnimals = true,  -- will be used by canTrigger default
    })
end

-- =====================
-- SELF-REGISTRATION WITH CORE
-- =====================

local function initWildlifeAPI()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerSubsystem then
        return false
    end

    g_RandomWorldEvents:registerSubsystem("wildlife", RWEWildlifeAPI)

    for _, entry in ipairs(RWEWildlifeAPI._pendingTicks) do
        g_RandomWorldEvents:registerTickHandler(entry.key, entry.fn)
    end
    RWEWildlifeAPI._pendingTicks = {}

    Logging.info("[RWEWildlifeAPI] v" .. RWEWildlifeAPI._VERSION .. " registered with RWE core")
    return true
end

if not initWildlifeAPI() then
    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, initWildlifeAPI)
    Logging.info("[RWEWildlifeAPI] Queued for deferred registration")
end

Logging.info("[RWEWildlifeAPI] Module loaded (v" .. RWEWildlifeAPI._VERSION .. ")")

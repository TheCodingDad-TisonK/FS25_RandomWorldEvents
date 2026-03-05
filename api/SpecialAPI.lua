-- =========================================================
-- RWESpecialAPI v1.0.0
-- Public subsystem API for the Special event category.
-- Third-party mods consume this table to register custom
-- special events with optional condition guards.
-- =========================================================
-- Author: TisonK  |  Part of FS25_RandomWorldEvents
-- =========================================================
--
-- USAGE (third-party mod):
--   if RWESpecialAPI and RWESpecialAPI.registerSpecialTrigger then
--     RWESpecialAPI:registerSpecialTrigger(
--       "myMod_harvest_moon",
--       function()  -- condition: only trigger at night
--         return g_currentMission and
--                g_currentMission.environment and
--                not g_currentMission.environment.isSunOn
--       end,
--       function(intensity)
--         if g_RandomWorldEvents then
--           g_RandomWorldEvents.EVENT_STATE.yieldBonus = 0.08 * intensity
--         end
--         return string.format("Harvest moon! Yields +%.0f%%", intensity * 8)
--       end
--     )
--   end
-- =========================================================

---@class RWESpecialAPI
RWESpecialAPI = {
    _VERSION  = "1.0.0",
    _CATEGORY = "special",

    _startCallbacks = {},
    _endCallbacks   = {},
    _pendingTicks   = {},
    _tickCounter    = 0,
}

-- =====================
-- CORE API SURFACE
-- =====================

--- Register a new special event.
--- def fields:
---   name         (string)   unique event identifier
---   func         (function) onStart handler: function(intensity) → string|nil
---   minIntensity (number)   minimum global intensity required (1-5)
---   weight       (number?)  random selection weight (default 1)
---   duration     (table?)   {min=N, max=M} in minutes (default {min=10,max=60})
---   canTrigger   (function?) condition guard; defaults to mission-exists check
---   onEnd        (function?) cleanup handler → string|nil
---@param def table
---@return boolean
function RWESpecialAPI:registerEvent(def)
    if type(def) ~= "table" then
        Logging.warning("[RWESpecialAPI] registerEvent: def must be a table")
        return false
    end
    if not def.name or not def.func then
        Logging.warning("[RWESpecialAPI] registerEvent: def.name and def.func are required")
        return false
    end
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[RWESpecialAPI] registerEvent: core not ready for event '" .. tostring(def.name)
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
        duration     = def.duration or { min = 10, max = 60 },
        minIntensity = def.minIntensity or 1,
        canTrigger   = def.canTrigger or function() return g_currentMission ~= nil end,

        onStart = function(intensity)
            local msg = userFunc(intensity)
            for _, cb in ipairs(api._startCallbacks) do
                pcall(cb, def, intensity)
            end
            return msg
        end,

        onEnd = function()
            local msg = userEnd and userEnd() or "Special event ended"
            for _, cb in ipairs(api._endCallbacks) do
                pcall(cb, def)
            end
            return msg
        end,
    }

    g_RandomWorldEvents:registerEvent(coreDef)
    return true
end

--- Returns a shallow copy of all registered special events.
---@return table[]
function RWESpecialAPI:getEventList()
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

--- Manually fire a named special event at the given intensity.
---@param name string
---@param intensity number  1-5
---@return string
function RWESpecialAPI:triggerEvent(name, intensity)
    if not g_RandomWorldEvents then
        return "[RWESpecialAPI] Core not available"
    end
    if g_RandomWorldEvents.EVENT_STATE.activeEvent ~= nil then
        return "[RWESpecialAPI] Another event is already active: "
            .. tostring(g_RandomWorldEvents.EVENT_STATE.activeEvent)
    end

    local event = g_RandomWorldEvents.EVENTS[name]
    if not event then
        return "[RWESpecialAPI] Event not found: " .. tostring(name)
    end
    if event.category ~= self._CATEGORY then
        return "[RWESpecialAPI] Event '" .. name .. "' is not a special event"
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

    Logging.info(string.format("[RWESpecialAPI] Triggered event '%s' at intensity %d", name, safeIntensity))
    return msg or ("Triggered: " .. name)
end

--- Returns true while any special event is active.
---@return boolean
function RWESpecialAPI:isEventActive()
    if not g_RandomWorldEvents then return false end
    local id = g_RandomWorldEvents.EVENT_STATE.activeEvent
    if not id then return false end
    local event = g_RandomWorldEvents.EVENTS[id]
    return event ~= nil and event.category == self._CATEGORY
end

--- Returns the active special event definition, or nil if none is active.
---@return table|nil
function RWESpecialAPI:getActiveEvent()
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
function RWESpecialAPI:registerTickHandler(fn)
    if type(fn) ~= "function" then return end
    self._tickCounter = self._tickCounter + 1
    local key = "RWESpecialAPI_tick_" .. self._tickCounter
    if g_RandomWorldEvents and g_RandomWorldEvents.registerTickHandler then
        g_RandomWorldEvents:registerTickHandler(key, fn)
    else
        table.insert(self._pendingTicks, { key = key, fn = fn })
    end
end

--- Returns the API semantic version string.
---@return string
function RWESpecialAPI:getVersion()
    return self._VERSION
end

--- Subscribe to event-start notifications for special events registered via this API.
---@param cb function(eventDef, intensity)
function RWESpecialAPI:onEventStart(cb)
    if type(cb) == "function" then
        table.insert(self._startCallbacks, cb)
    end
end

--- Subscribe to event-end notifications for special events registered via this API.
---@param cb function(eventDef)
function RWESpecialAPI:onEventEnd(cb)
    if type(cb) == "function" then
        table.insert(self._endCallbacks, cb)
    end
end

-- =====================
-- CATEGORY-SPECIFIC: CONDITION-GATED TRIGGER
-- =====================

--- Register a special event that only enters the trigger pool when `condition` returns true.
--- This is the canonical way for third-party mods to add situation-specific special events
--- (e.g. only during night, only in winter, only when money is below a threshold).
---
---   name      (string)   unique event identifier
---   condition (function) → boolean; called by canTrigger each tick
---   func      (function(intensity)) → string|nil; onStart handler
---   opts      (table?)   optional overrides: {minIntensity, duration, weight, onEnd}
---@param name      string
---@param condition function → boolean
---@param func      function(intensity) → string|nil
---@param opts      table|nil
---@return boolean
function RWESpecialAPI:registerSpecialTrigger(name, condition, func, opts)
    if type(name) ~= "string" then
        Logging.warning("[RWESpecialAPI] registerSpecialTrigger: name must be a string")
        return false
    end
    if type(condition) ~= "function" then
        Logging.warning("[RWESpecialAPI] registerSpecialTrigger: condition must be a function")
        return false
    end
    if type(func) ~= "function" then
        Logging.warning("[RWESpecialAPI] registerSpecialTrigger: func must be a function")
        return false
    end

    opts = opts or {}

    return self:registerEvent({
        name         = name,
        func         = func,
        minIntensity = opts.minIntensity or 1,
        weight       = opts.weight or 1,
        duration     = opts.duration,
        onEnd        = opts.onEnd,
        canTrigger   = function()
            if not g_currentMission then return false end
            local ok, result = pcall(condition)
            return ok and result == true
        end,
    })
end

-- =====================
-- SELF-REGISTRATION WITH CORE
-- =====================

local function initSpecialAPI()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerSubsystem then
        return false
    end

    g_RandomWorldEvents:registerSubsystem("special", RWESpecialAPI)

    for _, entry in ipairs(RWESpecialAPI._pendingTicks) do
        g_RandomWorldEvents:registerTickHandler(entry.key, entry.fn)
    end
    RWESpecialAPI._pendingTicks = {}

    Logging.info("[RWESpecialAPI] v" .. RWESpecialAPI._VERSION .. " registered with RWE core")
    return true
end

if not initSpecialAPI() then
    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, initSpecialAPI)
    Logging.info("[RWESpecialAPI] Queued for deferred registration")
end

Logging.info("[RWESpecialAPI] Module loaded (v" .. RWESpecialAPI._VERSION .. ")")

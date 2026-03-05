-- =========================================================
-- RWEFieldAPI v1.0.0
-- Public subsystem API for the Field event category.
-- Third-party mods consume this table to register custom
-- field events and query/override per-field yield values.
-- =========================================================
-- Author: TisonK  |  Part of FS25_RandomWorldEvents
-- =========================================================
--
-- USAGE (third-party mod):
--   if RWEFieldAPI and RWEFieldAPI.registerEvent then
--     RWEFieldAPI:registerEvent({
--       name        = "myMod_soil_enrichment",
--       minIntensity = 1,
--       func        = function(intensity)
--         if g_RandomWorldEvents then
--           g_RandomWorldEvents.EVENT_STATE.yieldBonus = 0.05 * intensity
--         end
--         return "Soil enriched! Yield +" .. intensity * 5 .. "%"
--       end,
--     })
--   end
-- =========================================================

---@class RWEFieldAPI
RWEFieldAPI = {
    _VERSION  = "1.0.0",
    _CATEGORY = "field",

    _startCallbacks = {},
    _endCallbacks   = {},
    _pendingTicks   = {},
    _tickCounter    = 0,
}

-- =====================
-- CORE API SURFACE
-- =====================

--- Register a new field event.
--- def fields:
---   name         (string)   unique event identifier
---   func         (function) onStart handler: function(intensity) → string|nil
---   minIntensity (number)   minimum global intensity required (1-5)
---   weight       (number?)  random selection weight (default 1)
---   duration     (table?)   {min=N, max=M} in minutes (default {min=30,max=120})
---   canTrigger   (function?) guard; defaults to field-manager check
---   onEnd        (function?) cleanup handler → string|nil
---@param def table
---@return boolean
function RWEFieldAPI:registerEvent(def)
    if type(def) ~= "table" then
        Logging.warning("[RWEFieldAPI] registerEvent: def must be a table")
        return false
    end
    if not def.name or not def.func then
        Logging.warning("[RWEFieldAPI] registerEvent: def.name and def.func are required")
        return false
    end
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[RWEFieldAPI] registerEvent: core not ready for event '" .. tostring(def.name)
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
        duration     = def.duration or { min = 30, max = 120 },
        minIntensity = def.minIntensity or 1,

        canTrigger = def.canTrigger or function()
            if g_fieldManager then
                local fields = g_fieldManager:getFields()
                return fields ~= nil and #fields > 0
            end
            return g_currentMission ~= nil
        end,

        onStart = function(intensity)
            local msg = userFunc(intensity)
            for _, cb in ipairs(api._startCallbacks) do
                pcall(cb, def, intensity)
            end
            return msg
        end,

        onEnd = function()
            local msg = userEnd and userEnd() or "Field event ended"
            for _, cb in ipairs(api._endCallbacks) do
                pcall(cb, def)
            end
            return msg
        end,
    }

    g_RandomWorldEvents:registerEvent(coreDef)
    return true
end

--- Returns a shallow copy of all registered field events.
---@return table[]
function RWEFieldAPI:getEventList()
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

--- Manually fire a named field event at the given intensity.
---@param name string
---@param intensity number  1-5
---@return string
function RWEFieldAPI:triggerEvent(name, intensity)
    if not g_RandomWorldEvents then
        return "[RWEFieldAPI] Core not available"
    end
    if g_RandomWorldEvents.EVENT_STATE.activeEvent ~= nil then
        return "[RWEFieldAPI] Another event is already active: "
            .. tostring(g_RandomWorldEvents.EVENT_STATE.activeEvent)
    end

    local event = g_RandomWorldEvents.EVENTS[name]
    if not event then
        return "[RWEFieldAPI] Event not found: " .. tostring(name)
    end
    if event.category ~= self._CATEGORY then
        return "[RWEFieldAPI] Event '" .. name .. "' is not a field event"
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

    Logging.info(string.format("[RWEFieldAPI] Triggered event '%s' at intensity %d", name, safeIntensity))
    return msg or ("Triggered: " .. name)
end

--- Returns true while any field event is active.
---@return boolean
function RWEFieldAPI:isEventActive()
    if not g_RandomWorldEvents then return false end
    local id = g_RandomWorldEvents.EVENT_STATE.activeEvent
    if not id then return false end
    local event = g_RandomWorldEvents.EVENTS[id]
    return event ~= nil and event.category == self._CATEGORY
end

--- Returns the active field event definition, or nil if none is active.
---@return table|nil
function RWEFieldAPI:getActiveEvent()
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
function RWEFieldAPI:registerTickHandler(fn)
    if type(fn) ~= "function" then return end
    self._tickCounter = self._tickCounter + 1
    local key = "RWEFieldAPI_tick_" .. self._tickCounter
    if g_RandomWorldEvents and g_RandomWorldEvents.registerTickHandler then
        g_RandomWorldEvents:registerTickHandler(key, fn)
    else
        table.insert(self._pendingTicks, { key = key, fn = fn })
    end
end

--- Returns the API semantic version string.
---@return string
function RWEFieldAPI:getVersion()
    return self._VERSION
end

--- Subscribe to event-start notifications for field events registered via this API.
---@param cb function(eventDef, intensity)
function RWEFieldAPI:onEventStart(cb)
    if type(cb) == "function" then
        table.insert(self._startCallbacks, cb)
    end
end

--- Subscribe to event-end notifications for field events registered via this API.
---@param cb function(eventDef)
function RWEFieldAPI:onEventEnd(cb)
    if type(cb) == "function" then
        table.insert(self._endCallbacks, cb)
    end
end

-- =====================
-- CATEGORY-SPECIFIC: PER-FIELD YIELD OVERRIDE
-- =====================

--- Apply a yield delta to a specific field (third-party hook).
--- Stored in EVENT_STATE.perFieldYield[fieldId].
--- Positive delta = bonus, negative = penalty.
--- EffectHooks and tick handlers should check this table for per-field adjustments.
---@param fieldId number   field identifier
---@param delta   number   additive yield modifier (e.g. 0.10 = +10%)
function RWEFieldAPI:modifyYield(fieldId, delta)
    if not g_RandomWorldEvents then
        Logging.warning("[RWEFieldAPI] modifyYield: core not available")
        return
    end

    local state = g_RandomWorldEvents.EVENT_STATE
    if not state.perFieldYield then
        state.perFieldYield = {}
    end

    state.perFieldYield[fieldId] = (state.perFieldYield[fieldId] or 0) + delta

    Logging.info(string.format(
        "[RWEFieldAPI] Field %d yield modifier: %+.3f (total: %+.3f)",
        fieldId, delta, state.perFieldYield[fieldId]
    ))
end

--- Return the cumulative yield modifier for a field, or 0 if none set.
---@param fieldId number
---@return number
function RWEFieldAPI:getYieldModifier(fieldId)
    if not g_RandomWorldEvents then return 0 end
    local pfy = g_RandomWorldEvents.EVENT_STATE.perFieldYield
    return (pfy and pfy[fieldId]) or 0
end

--- Clear all per-field yield overrides (call on event end if needed).
function RWEFieldAPI:clearYieldModifiers()
    if not g_RandomWorldEvents then return end
    g_RandomWorldEvents.EVENT_STATE.perFieldYield = nil
end

-- =====================
-- SELF-REGISTRATION WITH CORE
-- =====================

local function initFieldAPI()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerSubsystem then
        return false
    end

    g_RandomWorldEvents:registerSubsystem("field", RWEFieldAPI)

    for _, entry in ipairs(RWEFieldAPI._pendingTicks) do
        g_RandomWorldEvents:registerTickHandler(entry.key, entry.fn)
    end
    RWEFieldAPI._pendingTicks = {}

    Logging.info("[RWEFieldAPI] v" .. RWEFieldAPI._VERSION .. " registered with RWE core")
    return true
end

if not initFieldAPI() then
    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, initFieldAPI)
    Logging.info("[RWEFieldAPI] Queued for deferred registration")
end

Logging.info("[RWEFieldAPI] Module loaded (v" .. RWEFieldAPI._VERSION .. ")")

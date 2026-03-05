-- =========================================================
-- RWEEconomicAPI v1.0.0
-- Public subsystem API for the Economic event category.
-- Third-party mods consume this table to register custom
-- economic events and observe category activity.
-- =========================================================
-- Author: TisonK  |  Part of FS25_RandomWorldEvents
-- =========================================================
--
-- USAGE (third-party mod):
--   if RWEEconomicAPI and RWEEconomicAPI.registerEvent then
--     RWEEconomicAPI:registerEvent({
--       name        = "myMod_corn_subsidy",
--       minIntensity = 1,
--       func        = function(intensity)
--         g_currentMission:addMoney(intensity * 1000, ...)
--         return "Corn subsidy! +" .. intensity * 1000 .. "€"
--       end,
--     })
--   end
-- =========================================================

---@class RWEEconomicAPI
RWEEconomicAPI = {
    _VERSION  = "1.0.0",
    _CATEGORY = "economic",

    -- Subscriber callback lists (populated via :onEventStart / :onEventEnd)
    _startCallbacks = {},
    _endCallbacks   = {},

    -- Pending tick handlers registered before the core was ready
    _pendingTicks   = {},
    _tickCounter    = 0,
}

-- =====================
-- CORE API SURFACE
-- =====================

--- Register a new economic event.
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
function RWEEconomicAPI:registerEvent(def)
    if type(def) ~= "table" then
        Logging.warning("[RWEEconomicAPI] registerEvent: def must be a table")
        return false
    end
    if not def.name or not def.func then
        Logging.warning("[RWEEconomicAPI] registerEvent: def.name and def.func are required")
        return false
    end
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[RWEEconomicAPI] registerEvent: core not ready for event '" .. tostring(def.name)
            .. "'. Call from onMissionLoaded, not at file scope.")
        return false
    end

    -- Capture references for closure
    local api      = self
    local userFunc = def.func
    local userEnd  = def.onEnd

    local coreDef = {
        name         = def.name,
        category     = self._CATEGORY,
        weight       = def.weight or 1,
        duration     = def.duration or { min = 15, max = 60 },
        minIntensity = def.minIntensity or 1,
        canTrigger   = def.canTrigger or function() return g_currentMission ~= nil end,

        -- Wrap onStart to fire subscriber callbacks
        onStart = function(intensity)
            local msg = userFunc(intensity)
            for _, cb in ipairs(api._startCallbacks) do
                pcall(cb, def, intensity)
            end
            return msg
        end,

        -- Wrap onEnd to fire subscriber callbacks and clean up API-managed state.
        onEnd = function()
            local msg = userEnd and userEnd() or "Economic event ended"
            -- Clear any custom price modifiers set via setPriceModifier() during this event.
            -- Timed entries would self-prune lazily in the hook; indefinite ones require explicit cleanup.
            api:clearPriceModifiers()
            for _, cb in ipairs(api._endCallbacks) do
                pcall(cb, def)
            end
            return msg
        end,
    }

    g_RandomWorldEvents:registerEvent(coreDef)
    return true
end

--- Returns a shallow copy of all registered economic events.
---@return table[]
function RWEEconomicAPI:getEventList()
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

--- Manually fire a named economic event at the given intensity.
--- Returns a notification string or an error description.
---@param name string
---@param intensity number  1-5
---@return string
function RWEEconomicAPI:triggerEvent(name, intensity)
    if not g_RandomWorldEvents then
        return "[RWEEconomicAPI] Core not available"
    end
    if g_RandomWorldEvents.EVENT_STATE.activeEvent ~= nil then
        return "[RWEEconomicAPI] Another event is already active: "
            .. tostring(g_RandomWorldEvents.EVENT_STATE.activeEvent)
    end

    local event = g_RandomWorldEvents.EVENTS[name]
    if not event then
        return "[RWEEconomicAPI] Event not found: " .. tostring(name)
    end
    if event.category ~= self._CATEGORY then
        return "[RWEEconomicAPI] Event '" .. name .. "' is not an economic event"
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

    Logging.info(string.format("[RWEEconomicAPI] Triggered event '%s' at intensity %d", name, safeIntensity))
    return msg or ("Triggered: " .. name)
end

--- Returns true while any economic event is active.
---@return boolean
function RWEEconomicAPI:isEventActive()
    if not g_RandomWorldEvents then return false end
    local id = g_RandomWorldEvents.EVENT_STATE.activeEvent
    if not id then return false end
    local event = g_RandomWorldEvents.EVENTS[id]
    return event ~= nil and event.category == self._CATEGORY
end

--- Returns the active economic event definition, or nil if none is active.
---@return table|nil
function RWEEconomicAPI:getActiveEvent()
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
function RWEEconomicAPI:registerTickHandler(fn)
    if type(fn) ~= "function" then return end
    self._tickCounter = self._tickCounter + 1
    local key = "RWEEconomicAPI_tick_" .. self._tickCounter
    if g_RandomWorldEvents and g_RandomWorldEvents.registerTickHandler then
        -- Core is live — register directly; no need to buffer.
        g_RandomWorldEvents:registerTickHandler(key, fn)
    else
        -- Core not yet ready; buffer for deferred flush in initEconomicAPI().
        table.insert(self._pendingTicks, { key = key, fn = fn })
    end
end

--- Returns the API semantic version string.
---@return string
function RWEEconomicAPI:getVersion()
    return self._VERSION
end

--- Subscribe to event-start notifications for economic events registered via this API.
---@param cb function(eventDef, intensity)
function RWEEconomicAPI:onEventStart(cb)
    if type(cb) == "function" then
        table.insert(self._startCallbacks, cb)
    end
end

--- Subscribe to event-end notifications for economic events registered via this API.
---@param cb function(eventDef)
function RWEEconomicAPI:onEventEnd(cb)
    if type(cb) == "function" then
        table.insert(self._endCallbacks, cb)
    end
end

-- =====================
-- CATEGORY-SPECIFIC: PRICE MODIFIER
-- =====================

--- Set a custom crop price multiplier for a duration (third-party hook).
--- Stored in EVENT_STATE.customPriceModifiers for consumption by EffectHooks.
--- Pass nil for durationMin to apply indefinitely until the active event ends.
---@param cropType any   FillType constant or string key
---@param multiplier number  price scale factor (e.g. 1.20 = +20%)
---@param durationMin number|nil  duration in in-game minutes; nil = until event ends
function RWEEconomicAPI:setPriceModifier(cropType, multiplier, durationMin)
    if not g_RandomWorldEvents then
        Logging.warning("[RWEEconomicAPI] setPriceModifier: core not available")
        return
    end

    local state = g_RandomWorldEvents.EVENT_STATE
    if not state.customPriceModifiers then
        state.customPriceModifiers = {}
    end

    local expiresAt = nil
    if durationMin and g_currentMission then
        expiresAt = g_currentMission.time + (durationMin * 60000)
    end

    state.customPriceModifiers[cropType] = {
        multiplier = multiplier,
        expiresAt  = expiresAt,
    }

    Logging.info(string.format(
        "[RWEEconomicAPI] Price modifier: crop=%s multiplier=%.2f duration=%s min",
        tostring(cropType), multiplier, tostring(durationMin)
    ))
end

--- Retrieve the active price modifier for a given crop type, or nil if none/expired.
---@param cropType any
---@return number|nil  multiplier
function RWEEconomicAPI:getPriceModifier(cropType)
    if not g_RandomWorldEvents then return nil end
    local mods = g_RandomWorldEvents.EVENT_STATE.customPriceModifiers
    if not mods or not mods[cropType] then return nil end
    local mod = mods[cropType]
    if mod.expiresAt and g_currentMission and g_currentMission.time > mod.expiresAt then
        mods[cropType] = nil
        return nil
    end
    return mod.multiplier
end

--- Clear all custom price modifiers (e.g. on event end).
function RWEEconomicAPI:clearPriceModifiers()
    if not g_RandomWorldEvents then return end
    g_RandomWorldEvents.EVENT_STATE.customPriceModifiers = nil
end

-- =====================
-- SELF-REGISTRATION WITH CORE
-- =====================

local function initEconomicAPI()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerSubsystem then
        return false
    end

    g_RandomWorldEvents:registerSubsystem("economic", RWEEconomicAPI)

    -- Flush tick handlers buffered before the core was ready, then clear the queue.
    for _, entry in ipairs(RWEEconomicAPI._pendingTicks) do
        g_RandomWorldEvents:registerTickHandler(entry.key, entry.fn)
    end
    RWEEconomicAPI._pendingTicks = {}

    Logging.info("[RWEEconomicAPI] v" .. RWEEconomicAPI._VERSION .. " registered with RWE core")
    return true
end

if not initEconomicAPI() then
    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, initEconomicAPI)
    Logging.info("[RWEEconomicAPI] Queued for deferred registration")
end

Logging.info("[RWEEconomicAPI] Module loaded (v" .. RWEEconomicAPI._VERSION .. ")")

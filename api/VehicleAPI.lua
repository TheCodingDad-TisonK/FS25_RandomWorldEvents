-- =========================================================
-- RWEVehicleAPI v1.0.0
-- Public subsystem API for the Vehicle event category.
-- Third-party mods consume this table to register custom
-- vehicle events and apply vehicle modifiers at runtime.
-- =========================================================
-- Author: TisonK  |  Part of FS25_RandomWorldEvents
-- =========================================================
--
-- USAGE (third-party mod):
--   if RWEVehicleAPI and RWEVehicleAPI.registerEvent then
--     RWEVehicleAPI:registerEvent({
--       name        = "myMod_turbo_boost",
--       minIntensity = 1,
--       func        = function(intensity)
--         local v = g_currentMission and g_currentMission.controlledVehicle
--         if v then
--           RWEVehicleAPI:applyVehicleModifier(v, { speedMultiplier = 1.0 + 0.1 * intensity })
--         end
--         return string.format("Turbo engaged! +%.0f%% speed", intensity * 10)
--       end,
--     })
--   end
-- =========================================================

---@class RWEVehicleAPI
RWEVehicleAPI = {
    _VERSION  = "1.0.0",
    _CATEGORY = "vehicle",

    _startCallbacks = {},
    _endCallbacks   = {},
    _pendingTicks   = {},
    _tickCounter    = 0,

    -- Tracks vehicles modified via applyVehicleModifier for cleanup on event end
    _modifiedVehicles = {},
}

-- =====================
-- CORE API SURFACE
-- =====================

--- Register a new vehicle event.
--- def fields:
---   name         (string)   unique event identifier
---   func         (function) onStart handler: function(intensity) → string|nil
---   minIntensity (number)   minimum global intensity required (1-5)
---   weight       (number?)  random selection weight (default 1)
---   duration     (table?)   {min=N, max=M} in minutes (default {min=10,max=30})
---   canTrigger   (function?) guard; defaults to mission-exists check
---   onEnd        (function?) cleanup handler → string|nil
---@param def table
---@return boolean
function RWEVehicleAPI:registerEvent(def)
    if type(def) ~= "table" then
        Logging.warning("[RWEVehicleAPI] registerEvent: def must be a table")
        return false
    end
    if not def.name or not def.func then
        Logging.warning("[RWEVehicleAPI] registerEvent: def.name and def.func are required")
        return false
    end
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[RWEVehicleAPI] registerEvent: core not ready for event '" .. tostring(def.name)
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
        duration     = def.duration or { min = 10, max = 30 },
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
            -- Auto-restore any vehicles modified via applyVehicleModifier
            api:_restoreModifiedVehicles()

            local msg = userEnd and userEnd() or "Vehicle event ended"
            for _, cb in ipairs(api._endCallbacks) do
                pcall(cb, def)
            end
            return msg
        end,
    }

    g_RandomWorldEvents:registerEvent(coreDef)
    return true
end

--- Returns a shallow copy of all registered vehicle events.
---@return table[]
function RWEVehicleAPI:getEventList()
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

--- Manually fire a named vehicle event at the given intensity.
---@param name string
---@param intensity number  1-5
---@return string
function RWEVehicleAPI:triggerEvent(name, intensity)
    if not g_RandomWorldEvents then
        return "[RWEVehicleAPI] Core not available"
    end
    if g_RandomWorldEvents.EVENT_STATE.activeEvent ~= nil then
        return "[RWEVehicleAPI] Another event is already active: "
            .. tostring(g_RandomWorldEvents.EVENT_STATE.activeEvent)
    end

    local event = g_RandomWorldEvents.EVENTS[name]
    if not event then
        return "[RWEVehicleAPI] Event not found: " .. tostring(name)
    end
    if event.category ~= self._CATEGORY then
        return "[RWEVehicleAPI] Event '" .. name .. "' is not a vehicle event"
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

    Logging.info(string.format("[RWEVehicleAPI] Triggered event '%s' at intensity %d", name, safeIntensity))
    return msg or ("Triggered: " .. name)
end

--- Returns true while any vehicle event is active.
---@return boolean
function RWEVehicleAPI:isEventActive()
    if not g_RandomWorldEvents then return false end
    local id = g_RandomWorldEvents.EVENT_STATE.activeEvent
    if not id then return false end
    local event = g_RandomWorldEvents.EVENTS[id]
    return event ~= nil and event.category == self._CATEGORY
end

--- Returns the active vehicle event definition, or nil if none is active.
---@return table|nil
function RWEVehicleAPI:getActiveEvent()
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
function RWEVehicleAPI:registerTickHandler(fn)
    if type(fn) ~= "function" then return end
    self._tickCounter = self._tickCounter + 1
    local key = "RWEVehicleAPI_tick_" .. self._tickCounter
    if g_RandomWorldEvents and g_RandomWorldEvents.registerTickHandler then
        g_RandomWorldEvents:registerTickHandler(key, fn)
    else
        table.insert(self._pendingTicks, { key = key, fn = fn })
    end
end

--- Returns the API semantic version string.
---@return string
function RWEVehicleAPI:getVersion()
    return self._VERSION
end

--- Subscribe to event-start notifications for vehicle events registered via this API.
---@param cb function(eventDef, intensity)
function RWEVehicleAPI:onEventStart(cb)
    if type(cb) == "function" then
        table.insert(self._startCallbacks, cb)
    end
end

--- Subscribe to event-end notifications for vehicle events registered via this API.
---@param cb function(eventDef)
function RWEVehicleAPI:onEventEnd(cb)
    if type(cb) == "function" then
        table.insert(self._endCallbacks, cb)
    end
end

-- =====================
-- CATEGORY-SPECIFIC: VEHICLE MODIFIER
-- =====================

--- Apply runtime modifiers to one vehicle or all farm vehicles.
--- Pass nil for vehicleOrNil to target all vehicles owned by the player's farm.
---
--- modifierTable fields (all optional):
---   speedMultiplier  (number)  multiplier applied to speedLimit (e.g. 1.3 = +30%)
---   damage           (number)  raw damage amount added via addDamageAmount (0.0–1.0)
---   repair           (boolean) if true, calls vehicle:repair() on each vehicle
---
--- Originals are stored and automatically restored when the event ends via onEnd.
---@param vehicleOrNil table|nil
---@param modifierTable table
function RWEVehicleAPI:applyVehicleModifier(vehicleOrNil, modifierTable)
    if not modifierTable then
        Logging.warning("[RWEVehicleAPI] applyVehicleModifier: modifierTable is required")
        return
    end

    local targets = {}
    if vehicleOrNil then
        targets = { vehicleOrNil }
    elseif g_currentMission and g_currentMission.vehicles then
        local farmId = g_currentMission.player and g_currentMission.player.farmId or 0
        if farmId > 0 then
            for _, v in pairs(g_currentMission.vehicles) do
                if v and v.getOwnerFarmId and v:getOwnerFarmId() == farmId then
                    table.insert(targets, v)
                end
            end
        end
    end

    for _, vehicle in ipairs(targets) do
        -- Speed modifier
        if modifierTable.speedMultiplier and vehicle.setSpeedLimit then
            if not vehicle._rweApiOriginalSpeed then
                -- First application: snapshot the original speed limit.
                vehicle._rweApiOriginalSpeed = vehicle.speedLimit or 100
                -- Track for restore on event end; only add once per vehicle.
                table.insert(self._modifiedVehicles, vehicle)
            end
            local newSpeed = vehicle._rweApiOriginalSpeed * modifierTable.speedMultiplier
            vehicle.speedLimit = newSpeed
            vehicle:setSpeedLimit(newSpeed)
        end

        -- Damage
        if modifierTable.damage and vehicle.addDamageAmount then
            vehicle:addDamageAmount(math.min(modifierTable.damage, 1.0))
        end

        -- Repair
        if modifierTable.repair and vehicle.repair then
            vehicle:repair()
        end
    end

    Logging.info(string.format(
        "[RWEVehicleAPI] Applied modifier to %d vehicle(s)", #targets
    ))
end

--- Internal: restore all vehicles modified by applyVehicleModifier.
function RWEVehicleAPI:_restoreModifiedVehicles()
    for _, vehicle in ipairs(self._modifiedVehicles) do
        if vehicle and vehicle._rweApiOriginalSpeed and vehicle.setSpeedLimit then
            vehicle.speedLimit = vehicle._rweApiOriginalSpeed
            vehicle:setSpeedLimit(vehicle._rweApiOriginalSpeed)
            vehicle._rweApiOriginalSpeed = nil
        end
    end
    self._modifiedVehicles = {}
end

-- =====================
-- SELF-REGISTRATION WITH CORE
-- =====================

local function initVehicleAPI()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerSubsystem then
        return false
    end

    g_RandomWorldEvents:registerSubsystem("vehicle", RWEVehicleAPI)

    for _, entry in ipairs(RWEVehicleAPI._pendingTicks) do
        g_RandomWorldEvents:registerTickHandler(entry.key, entry.fn)
    end
    RWEVehicleAPI._pendingTicks = {}

    Logging.info("[RWEVehicleAPI] v" .. RWEVehicleAPI._VERSION .. " registered with RWE core")
    return true
end

if not initVehicleAPI() then
    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, initVehicleAPI)
    Logging.info("[RWEVehicleAPI] Queued for deferred registration")
end

Logging.info("[RWEVehicleAPI] Module loaded (v" .. RWEVehicleAPI._VERSION .. ")")

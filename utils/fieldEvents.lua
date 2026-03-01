-- =========================================================
-- Random World Events (version 2.0.0.0) - FS25
-- =========================================================
-- Field events for FS25
-- =========================================================
-- Author: TisonK
-- =========================================================

local fieldEvents = {}

fieldEvents.eventList = {
    {name="crop_yield_bonus", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.yieldBonus = 0.05 * intensity
        end
        return string.format("Crop yield +%.0f%%!", (0.05 * intensity) * 100)
    end},

    {name="crop_yield_penalty", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.yieldMalus = 0.05 * intensity
        end
        return string.format("Crop yield -%.0f%%!", (0.05 * intensity) * 100)
    end},

    {name="fertilizer_bonus", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fertilizerBonus = 0.10 + 0.05 * intensity
        end
        return string.format("Fertilizer effectiveness +%.0f%%!", (0.10 + 0.05 * intensity) * 100)
    end},

    {name="fertilizer_penalty", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fertilizerMalus = 0.10 + 0.05 * intensity
        end
        return string.format("Fertilizer effectiveness -%.0f%%!", (0.10 + 0.05 * intensity) * 100)
    end},

    {name="seed_growth_bonus", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.seedBonus = 0.10 + 0.05 * intensity
        end
        return string.format("Seeds grow faster! +%.0f%% growth income!", (0.10 + 0.05 * intensity) * 100)
    end},

    {name="seed_growth_penalty", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.seedMalus = 0.10 + 0.05 * intensity
        end
        return string.format("Seeds grow slower! -%.0f%% growth income!", (0.10 + 0.05 * intensity) * 100)
    end},

    {name="harvest_bonus", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.harvestBonus = 0.10 + 0.05 * intensity
        end
        return string.format("Harvest increased! +%.0f%% sell price!", (0.10 + 0.05 * intensity) * 100)
    end},

    {name="harvest_penalty", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.harvestMalus = 0.10 + 0.05 * intensity
        end
        return string.format("Harvest reduced! -%.0f%% sell price!", (0.10 + 0.05 * intensity) * 100)
    end},

    {name="field_sale_bonus", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fieldSaleBonus = 0.05 * intensity
        end
        return string.format("Field sales increased! +%.0f%%!", (0.05 * intensity) * 100)
    end},

    {name="field_sale_penalty", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fieldSaleMalus = 0.05 * intensity
        end
        return string.format("Field sales decreased! -%.0f%%!", (0.05 * intensity) * 100)
    end},
}

-- =====================
-- TICK HANDLER
-- Delivers periodic cash effects every 60 in-game seconds for
-- flags that cannot be mapped to a sell-price hook (growth/
-- fertilizer savings proxies).
-- =====================
local function fieldTickHandler(rwe)
    if not g_currentMission then return end
    local s = rwe.EVENT_STATE
    local t = g_currentMission.time
    local lastTick = s.lastFieldTick or 0
    if t - lastTick < 60000 then return end
    s.lastFieldTick = t

    local farmId = g_currentMission.player and g_currentMission.player.farmId or 0
    if farmId == 0 then return end

    local amount = 0

    if s.fertilizerBonus then
        amount = amount + math.floor(500 * s.fertilizerBonus)
    end
    if s.fertilizerMalus then
        amount = amount - math.floor(400 * s.fertilizerMalus)
    end
    if s.seedBonus then
        amount = amount + math.floor(300 * s.seedBonus)
    end
    if s.seedMalus then
        amount = amount - math.floor(250 * s.seedMalus)
    end

    if amount ~= 0 and g_currentMission.addMoney then
        g_currentMission:addMoney(amount, farmId, MoneyType.OTHER, false)
        local label = amount > 0 and "Field bonus" or "Field penalty"
        Logging.info(string.format("[FieldEvents] %s: %+d€/min", label, amount))
    end
end

-- =====================
-- REGISTER FIELD EVENTS
-- =====================
local function registerFieldEvents()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[FieldEvents] g_RandomWorldEvents not available yet")
        return false
    end

    for _, e in ipairs(fieldEvents.eventList) do
        g_RandomWorldEvents:registerEvent({
            name = e.name,
            category = "field",
            weight = 1,
            duration = {min = 30, max = 120},
            minIntensity = e.minI,
            canTrigger = function()
                if g_fieldManager then
                    local fields = g_fieldManager:getFields()
                    return fields ~= nil and #fields > 0
                end
                return g_currentMission ~= nil
            end,
            onStart = e.func,
            onEnd = function()
                if g_RandomWorldEvents then
                    local s = g_RandomWorldEvents.EVENT_STATE
                    s.yieldBonus    = nil
                    s.yieldMalus    = nil
                    s.fertilizerBonus = nil
                    s.fertilizerMalus = nil
                    s.seedBonus     = nil
                    s.seedMalus     = nil
                    s.harvestBonus  = nil
                    s.harvestMalus  = nil
                    s.fieldSaleBonus = nil
                    s.fieldSaleMalus = nil
                    s.lastFieldTick = nil
                end
                return "Field event ended"
            end
        })
    end

    g_RandomWorldEvents:registerTickHandler("fieldEvents", fieldTickHandler)

    Logging.info("[FieldEvents] Registered " .. #fieldEvents.eventList .. " field events")
    return true
end

-- =====================
-- DELAYED REGISTRATION
-- =====================
if g_RandomWorldEvents and g_RandomWorldEvents.registerEvent then
    registerFieldEvents()
else
    local function delayedRegistration()
        if registerFieldEvents() then
            Logging.info("[FieldEvents] Successfully registered via delayed registration")
        end
    end

    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, delayedRegistration)

    Logging.info("[FieldEvents] Added to pending registrations")
end

Logging.info("[FieldEvents] Module loaded successfully")

-- =========================================================
-- Random World Events (version 2.0.0.5) - FS25
-- =========================================================
-- Special events for FS25
-- =========================================================
-- Author: TisonK
-- =========================================================

local specialEvents = {}

specialEvents.eventList = {
    {name="time_acceleration", minI=1, func=function(intensity)
        if not g_RandomWorldEvents then return "Time acceleration!" end

        if not g_RandomWorldEvents.EVENT_STATE.originalTimeScale then
            g_RandomWorldEvents.EVENT_STATE.originalTimeScale = g_currentMission.missionInfo.timeScale
        end
        g_currentMission.missionInfo.timeScale = g_RandomWorldEvents.EVENT_STATE.originalTimeScale * (5 * intensity)
        return "TIME ACCELERATION!"
    end},

    {name="time_slowdown", minI=1, func=function(intensity)
        if not g_RandomWorldEvents then return "Time slowdown!" end

        if not g_RandomWorldEvents.EVENT_STATE.originalTimeScale then
            g_RandomWorldEvents.EVENT_STATE.originalTimeScale = g_currentMission.missionInfo.timeScale
        end
        g_currentMission.missionInfo.timeScale = g_RandomWorldEvents.EVENT_STATE.originalTimeScale / (2 * intensity)
        return "TIME SLOWDOWN!"
    end},

    {name="bonus_xp", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.xpBonus = 0.1 * intensity
        end
        return string.format("XP gain increased! +%.0f%% rep/min!", (0.1 * intensity) * 100)
    end},

    {name="malus_xp", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.xpMalus = 0.1 * intensity
        end
        return string.format("XP gain decreased! -%.0f%% rep/min!", (0.1 * intensity) * 100)
    end},

    {name="money_bonus", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.moneyBonus = 0.1 * intensity
        end
        return string.format("Money gain increased! +€%d/min!", math.floor(500 * 0.1 * intensity))
    end},

    {name="money_malus", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.moneyMalus = 0.1 * intensity
        end
        return string.format("Money gain decreased! -€%d/min!", math.floor(400 * 0.1 * intensity))
    end},

    {name="special_event_festival", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.marketBonus = 0.05 + 0.03 * intensity
            g_RandomWorldEvents.EVENT_STATE.moneyBonus  = 0.10 + 0.05 * intensity
        end
        return string.format(
            "Festival in town! Prices +%.0f%%, income +€%d/min!",
            (0.05 + 0.03 * intensity) * 100,
            math.floor(500 * (0.10 + 0.05 * intensity))
        )
    end},

    {name="equipment_durability_boost", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.durabilityBoost = 0.15 + 0.05 * intensity
        end
        return string.format("Equipment durability increased! -%.0f%% damage rate!", (0.15 + 0.05 * intensity) * 100)
    end},

    {name="equipment_durability_drop", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.durabilityMalus = 0.15 + 0.05 * intensity
        end
        return string.format("Equipment durability decreased! +%.0f%% damage rate!", (0.15 + 0.05 * intensity) * 100)
    end},

    {name="bonus_trade_prices", minI=1, func=function(intensity)
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.tradeBonus = 0.10 + 0.05 * intensity
        end
        return string.format("Better trade prices! +%.0f%% on all sales!", (0.10 + 0.05 * intensity) * 100)
    end},
}

-- =====================
-- TICK HANDLER
-- Delivers periodic cash and XP effects every 60 in-game seconds.
-- =====================
local function specialTickHandler(rwe)
    if not g_currentMission then return end
    local s = rwe.EVENT_STATE
    local t = g_currentMission.time
    local lastTick = s.lastSpecialTick or 0
    if t - lastTick < 60000 then return end
    s.lastSpecialTick = t

    local farmId = g_currentMission.player and g_currentMission.player.farmId or 0
    if farmId == 0 then return end

    local amount = 0
    if s.moneyBonus then
        local bonus = math.floor(500 * s.moneyBonus)
        amount = amount + bonus
        Logging.info(string.format("[SpecialEvents] Money bonus: +€%d", bonus))
    end
    if s.moneyMalus then
        local malus = math.floor(400 * s.moneyMalus)
        amount = amount - malus
        Logging.info(string.format("[SpecialEvents] Money malus: -€%d", malus))
    end

    if amount ~= 0 and g_currentMission.addMoney then
        g_currentMission:addMoney(amount, farmId, MoneyType.OTHER, false)
    end

    -- XP / reputation adjustments
    if (s.xpBonus or s.xpMalus) and g_farmManager then
        local farm = g_farmManager:getFarmById(farmId)
        if farm and farm.repPoints ~= nil then
            if s.xpBonus then
                local pts = math.floor(10 * s.xpBonus)
                farm.repPoints = farm.repPoints + pts
                Logging.info(string.format("[SpecialEvents] XP bonus: +%d rep pts", pts))
            end
            if s.xpMalus then
                local pts = math.floor(8 * s.xpMalus)
                farm.repPoints = math.max(0, farm.repPoints - pts)
                Logging.info(string.format("[SpecialEvents] XP malus: -%d rep pts", pts))
            end
        end
    end
end

-- =====================
-- REGISTER SPECIAL EVENTS
-- =====================
local function registerSpecialEvents()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[SpecialEvents] g_RandomWorldEvents not available yet")
        return false
    end

    for _, e in ipairs(specialEvents.eventList) do
        g_RandomWorldEvents:registerEvent({
            name = e.name,
            category = "special",
            weight = 1,
            duration = {min = 10, max = 60},
            minIntensity = e.minI,
            canTrigger = function()
                return g_currentMission ~= nil
            end,
            onStart = e.func,
            onEnd = function()
                if g_RandomWorldEvents then
                    local s = g_RandomWorldEvents.EVENT_STATE
                    if s.originalTimeScale then
                        g_currentMission.missionInfo.timeScale = s.originalTimeScale
                        s.originalTimeScale = nil
                    end
                    s.xpBonus        = nil
                    s.xpMalus        = nil
                    s.moneyBonus     = nil
                    s.moneyMalus     = nil
                    s.durabilityBoost = nil
                    s.durabilityMalus = nil
                    s.tradeBonus     = nil
                    s.marketBonus    = nil  -- festival sets this
                    s.lastSpecialTick = nil
                end
                return "Special event ended"
            end
        })
    end

    g_RandomWorldEvents:registerTickHandler("specialEvents", specialTickHandler)

    Logging.info("[SpecialEvents] Registered " .. #specialEvents.eventList .. " special events")
    return true
end

-- =====================
-- DELAYED REGISTRATION
-- =====================
if g_RandomWorldEvents and g_RandomWorldEvents.registerEvent then
    registerSpecialEvents()
else
    local function delayedRegistration()
        if registerSpecialEvents() then
            Logging.info("[SpecialEvents] Successfully registered via delayed registration")
        end
    end

    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, delayedRegistration)

    Logging.info("[SpecialEvents] Added to pending registrations")
end

Logging.info("[SpecialEvents] Module loaded successfully")

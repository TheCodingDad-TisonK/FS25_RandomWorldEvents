-- =========================================================
-- Random World Events (version 2.0.0.0) - FS25
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
        return "XP gain increased!" 
    end},
    
    {name="malus_xp", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.xpMalus = 0.1 * intensity 
        end
        return "XP gain decreased!" 
    end},
    
    {name="money_bonus", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.moneyBonus = 0.1 * intensity 
        end
        return "Money gain increased!" 
    end},
    
    {name="money_malus", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.moneyMalus = 0.1 * intensity 
        end
        return "Money gain decreased!" 
    end},
    
    {name="special_event_festival", minI=1, func=function() 
        return "Festival in town!" 
    end},
    
    {name="equipment_durability_boost", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.durabilityBoost = true 
        end
        return "Equipment durability increased!" 
    end},
    
    {name="equipment_durability_drop", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.durabilityMalus = true 
        end
        return "Equipment durability decreased!" 
    end},
    
    {name="bonus_trade_prices", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.tradeBonus = true 
        end
        return "Better trade prices!" 
    end},
}

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
                    if g_RandomWorldEvents.EVENT_STATE.originalTimeScale then
                        g_currentMission.missionInfo.timeScale = g_RandomWorldEvents.EVENT_STATE.originalTimeScale
                        g_RandomWorldEvents.EVENT_STATE.originalTimeScale = nil
                    end
                    
                    g_RandomWorldEvents.EVENT_STATE.xpBonus = nil
                    g_RandomWorldEvents.EVENT_STATE.xpMalus = nil
                    g_RandomWorldEvents.EVENT_STATE.moneyBonus = nil
                    g_RandomWorldEvents.EVENT_STATE.moneyMalus = nil
                    g_RandomWorldEvents.EVENT_STATE.durabilityBoost = nil
                    g_RandomWorldEvents.EVENT_STATE.durabilityMalus = nil
                    g_RandomWorldEvents.EVENT_STATE.tradeBonus = nil
                end
                return "Special event ended"
            end
        })
    end
    
    Logging.info("[SpecialEvents] Registered " .. #specialEvents.eventList .. " special events")
    return true
end

-- =====================
-- DELAYED REGISTRATION
-- =====================
if g_RandomWorldEvents and g_RandomWorldEvents.registerEvent then
    -- Register immediately if available
    registerSpecialEvents()
else
    -- Schedule for later registration
    local function delayedRegistration()
        if registerSpecialEvents() then
            Logging.info("[SpecialEvents] Successfully registered via delayed registration")
        end
    end
    
    -- Store for later
    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then 
        RandomWorldEvents.pendingRegistrations = {} 
    end
    table.insert(RandomWorldEvents.pendingRegistrations, delayedRegistration)
    
    Logging.info("[SpecialEvents] Added to pending registrations")
end

Logging.info("[SpecialEvents] Module loaded successfully")
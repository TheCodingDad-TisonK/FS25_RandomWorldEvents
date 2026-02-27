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
    
    {name="fertilizer_bonus", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fertilizerBonus = true 
        end
        return "Fertilizer effect doubled!" 
    end},
    
    {name="fertilizer_penalty", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fertilizerMalus = true 
        end
        return "Fertilizer effect halved!" 
    end},
    
    {name="seed_growth_bonus", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.seedBonus = true 
        end
        return "Seeds grow faster!" 
    end},
    
    {name="seed_growth_penalty", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.seedMalus = true 
        end
        return "Seeds grow slower!" 
    end},
    
    {name="harvest_bonus", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.harvestBonus = true 
        end
        return "Harvest increased!" 
    end},
    
    {name="harvest_penalty", minI=1, func=function() 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.harvestMalus = true 
        end
        return "Harvest reduced!" 
    end},
    
    {name="field_sale_bonus", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fieldSaleBonus = 0.05 * intensity 
        end
        return "Field sales increased!" 
    end},
    
    {name="field_sale_penalty", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fieldSaleMalus = 0.05 * intensity 
        end
        return "Field sales decreased!" 
    end},
}

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
                return g_currentMission ~= nil and 
                       g_currentMission.fieldController ~= nil and 
                       g_currentMission.fieldController.fields and
                       #g_currentMission.fieldController.fields > 0 
            end,
            onStart = e.func,
            onEnd = function()
                if g_RandomWorldEvents then
                    g_RandomWorldEvents.EVENT_STATE.yieldBonus = nil
                    g_RandomWorldEvents.EVENT_STATE.yieldMalus = nil
                    g_RandomWorldEvents.EVENT_STATE.fertilizerBonus = nil
                    g_RandomWorldEvents.EVENT_STATE.fertilizerMalus = nil
                    g_RandomWorldEvents.EVENT_STATE.seedBonus = nil
                    g_RandomWorldEvents.EVENT_STATE.seedMalus = nil
                    g_RandomWorldEvents.EVENT_STATE.harvestBonus = nil
                    g_RandomWorldEvents.EVENT_STATE.harvestMalus = nil
                    g_RandomWorldEvents.EVENT_STATE.fieldSaleBonus = nil
                    g_RandomWorldEvents.EVENT_STATE.fieldSaleMalus = nil
                end
                return "Field event ended"
            end
        })
    end
    
    Logging.info("[FieldEvents] Registered " .. #fieldEvents.eventList .. " field events")
    return true
end

-- =====================
-- DELAYED REGISTRATION
-- =====================
if g_RandomWorldEvents and g_RandomWorldEvents.registerEvent then
    -- Register immediately if available
    registerFieldEvents()
else
    -- Schedule for later registration
    local function delayedRegistration()
        if registerFieldEvents() then
            Logging.info("[FieldEvents] Successfully registered via delayed registration")
        end
    end
    
    -- Store for later
    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then 
        RandomWorldEvents.pendingRegistrations = {} 
    end
    table.insert(RandomWorldEvents.pendingRegistrations, delayedRegistration)
    
    Logging.info("[FieldEvents] Added to pending registrations")
end

Logging.info("[FieldEvents] Module loaded successfully")
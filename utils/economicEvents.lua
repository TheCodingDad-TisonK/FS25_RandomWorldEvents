-- =========================================================
-- Random World Events (version 2.0.0.0) - FS25
-- =========================================================
-- Economic events for FS25
-- =========================================================
-- Author: TisonK
-- =========================================================

local economicEvents = {}

economicEvents.getFarmId = function()
    return g_currentMission and g_currentMission.player and g_currentMission.player.farmId or 0
end

economicEvents.getFarmMoney = function()
    local farmId = economicEvents.getFarmId()
    if farmId > 0 and g_farmManager then
        local farm = g_farmManager:getFarmById(farmId)
        return farm and farm.money or 0
    end
    return 0
end

-- =====================
-- ECONOMIC EVENTS
-- =====================
economicEvents.eventList = {
    {name="government_subsidy", minI=1, func=function(intensity) 
        local amount = 5000 + intensity * 2500 
        if g_currentMission and g_currentMission.addMoney then
            g_currentMission:addMoney(amount, economicEvents.getFarmId(), MoneyType.OTHER, true) 
        end
        return string.format("Government subsidy! +€%d", amount) 
    end},
    
    {name="market_boom", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.marketBonus = 0.1 + intensity * 0.05 
        end
        return string.format("MARKET BOOM! +%.0f%% sell price", (0.1 + intensity * 0.05) * 100) 
    end},
    
    {name="market_crash", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.marketMalus = 0.1 + intensity * 0.05 
        end
        return string.format("MARKET CRASH! -%.0f%% sell price", (0.1 + intensity * 0.05) * 100) 
    end},
    
    {name="sudden_expense", minI=1, func=function(intensity) 
        local amount = 2000 + 1000 * intensity 
        if g_currentMission and g_currentMission.addMoney then
            g_currentMission:addMoney(-amount, economicEvents.getFarmId(), MoneyType.OTHER, true) 
        end
        return string.format("Unexpected expense! -€%d", amount) 
    end},
    
    {name="farmer_donation", minI=1, func=function(intensity) 
        local amount = 1000 * intensity 
        if g_currentMission and g_currentMission.addMoney then
            g_currentMission:addMoney(amount, economicEvents.getFarmId(), MoneyType.OTHER, true) 
        end
        return string.format("Farmers donated €%d", amount) 
    end},
    
    {name="seed_discount", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.seedDiscount = 0.1 + 0.05 * intensity 
        end
        return string.format("Seed discount active! -%.0f%%", (0.1 + 0.05 * intensity) * 100) 
    end},
    
    {name="fertilizer_discount", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fertilizerDiscount = 0.1 + 0.05 * intensity 
        end
        return string.format("Fertilizer discount! -%.0f%%", (0.1 + 0.05 * intensity) * 100) 
    end},
    
    {name="fuel_discount", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.fuelDiscount = 0.1 + 0.05 * intensity 
        end
        return string.format("Fuel discount! -%.0f%%", (0.1 + 0.05 * intensity) * 100) 
    end},
    
    {name="equipment_discount", minI=1, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.equipmentDiscount = 0.1 + 0.05 * intensity 
        end
        return string.format("Equipment discount! -%.0f%%", (0.1 + 0.05 * intensity) * 100) 
    end},
    
    {name="insurance_bonus", minI=1, func=function(intensity) 
        local amount = 3000 + intensity * 1000
        if g_currentMission and g_currentMission.addMoney then
            g_currentMission:addMoney(amount, economicEvents.getFarmId(), MoneyType.OTHER, true)
        end
        return string.format("Insurance payout! +€%d", amount)
    end},
    
    {name="tax_refund", minI=1, func=function(intensity) 
        local farmMoney = economicEvents.getFarmMoney()
        local refundAmount = math.min(farmMoney * 0.05 * intensity, 10000)
        if refundAmount > 100 and g_currentMission and g_currentMission.addMoney then
            g_currentMission:addMoney(refundAmount, economicEvents.getFarmId(), MoneyType.OTHER, true)
            return string.format("Tax refund! +€%d", math.floor(refundAmount))
        end
        return "Small tax refund processed"
    end},
    
    {name="price_fixing", minI=2, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.priceFixing = 0.15 + 0.05 * intensity
            g_RandomWorldEvents.EVENT_STATE.priceFixingDuration = 15 * intensity
        end
        return string.format("Price fixing scandal! Sell prices fixed at +%.0f%%", (0.15 + 0.05 * intensity) * 100)
    end},
    
    {name="loan_interest", minI=1, func=function(intensity) 
        local farmMoney = economicEvents.getFarmMoney()
        local interest = farmMoney * 0.02 * intensity
        if interest > 100 and g_currentMission and g_currentMission.addMoney then
            g_currentMission:addMoney(-interest, economicEvents.getFarmId(), MoneyType.LOAN_INTEREST, true)
            return string.format("Loan interest due! -€%d", math.floor(interest))
        end
        return "Minimal loan interest charged"
    end},
    
    {name="export_opportunity", minI=3, func=function(intensity) 
        local bonus = 0.25 + 0.05 * intensity
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.exportBonus = bonus
            g_RandomWorldEvents.EVENT_STATE.exportDuration = 30 * intensity
        end
        return string.format("Export opportunity! +%.0f%% on all exports", bonus * 100)
    end},
    
    {name="economic_crisis", minI=4, func=function(intensity) 
        if g_RandomWorldEvents then
            g_RandomWorldEvents.EVENT_STATE.economicCrisis = {
                marketMalus = 0.2 + 0.1 * intensity,
                loanPenalty = 0.05 * intensity,
                duration = 60 * intensity
            }
        end
        return string.format("ECONOMIC CRISIS! Market -%.0f%%, loans +%.0f%%", 
            (0.2 + 0.1 * intensity) * 100,
            (0.05 * intensity) * 100)
    end}
}

-- =====================
-- TICK HANDLER
-- =====================
-- Every 60 in-game seconds: deliver cash savings for active discount
-- events and loan penalties for economic crises.  Price-hook-managed
-- flags (marketBonus, priceFixing, exportBonus) are only logged here.
local function economicTickHandler(rwe)
    local s = rwe.EVENT_STATE
    if not g_currentMission then return end

    local t = g_currentMission.time
    local lastTick = s.lastEconomicTick or 0
    if t - lastTick < 60000 then return end
    s.lastEconomicTick = t

    local farmId = g_currentMission.player and g_currentMission.player.farmId or 0
    if farmId == 0 then return end

    local amount = 0

    -- Discount events: delivered as per-minute cash savings proxies
    if s.seedDiscount then
        local savings = math.floor(500 * s.seedDiscount)
        amount = amount + savings
        Logging.info(string.format("[EconomicEvents] Seed discount savings: +€%d", savings))
    end
    if s.fertilizerDiscount then
        local savings = math.floor(400 * s.fertilizerDiscount)
        amount = amount + savings
        Logging.info(string.format("[EconomicEvents] Fertilizer discount savings: +€%d", savings))
    end
    if s.fuelDiscount then
        local savings = math.floor(300 * s.fuelDiscount)
        amount = amount + savings
        Logging.info(string.format("[EconomicEvents] Fuel discount savings: +€%d", savings))
    end
    if s.equipmentDiscount then
        local savings = math.floor(350 * s.equipmentDiscount)
        amount = amount + savings
        Logging.info(string.format("[EconomicEvents] Equipment discount savings: +€%d", savings))
    end

    -- Economic crisis loan penalty
    if s.economicCrisis and s.economicCrisis.loanPenalty then
        local penalty = math.floor(1000 * s.economicCrisis.loanPenalty)
        amount = amount - penalty
        Logging.info(string.format("[EconomicEvents] Crisis loan penalty: -€%d", penalty))
    end

    if amount ~= 0 and g_currentMission.addMoney then
        g_currentMission:addMoney(amount, farmId, MoneyType.OTHER, false)
    end

    -- Log price-hook-managed flags (informational only)
    if s.marketBonus then
        Logging.info(string.format("[EconomicEvents] Market boom active: +%.0f%% sell prices", s.marketBonus * 100))
    end
    if s.marketMalus then
        Logging.info(string.format("[EconomicEvents] Market crash active: -%.0f%% sell prices", s.marketMalus * 100))
    end
    if s.priceFixing then
        Logging.info(string.format("[EconomicEvents] Price fixing active: +%.0f%% sell prices", s.priceFixing * 100))
    end
    if s.exportBonus then
        Logging.info(string.format("[EconomicEvents] Export bonus active: +%.0f%% on exports", s.exportBonus * 100))
    end
    if s.economicCrisis and s.economicCrisis.marketMalus then
        Logging.info(string.format("[EconomicEvents] Economic crisis: Market -%.0f%%", s.economicCrisis.marketMalus * 100))
    end
end

-- =====================
-- REGISTER ECONOMIC EVENTS
-- =====================
local function registerEconomicEvents()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[EconomicEvents] g_RandomWorldEvents not available yet")
        return false
    end

    for _, e in ipairs(economicEvents.eventList) do
        g_RandomWorldEvents:registerEvent({
            name = e.name,
            category = "economic",
            weight = 1,
            duration = {min = 15, max = 60},
            minIntensity = e.minI,
            canTrigger = function()
                return g_currentMission ~= nil
            end,
            onStart = e.func,
            onEnd = function()
                if g_RandomWorldEvents then
                    local s = g_RandomWorldEvents.EVENT_STATE
                    s.marketBonus        = nil
                    s.marketMalus        = nil
                    s.seedDiscount       = nil
                    s.fertilizerDiscount = nil
                    s.fuelDiscount       = nil
                    s.equipmentDiscount  = nil
                    s.priceFixing        = nil
                    s.exportBonus        = nil
                    s.economicCrisis     = nil
                    s.lastEconomicTick   = nil
                end
                return "Economic event ended"
            end
        })
    end

    -- Register the per-tick logging handler with the core.
    g_RandomWorldEvents:registerTickHandler("economicEvents", economicTickHandler)

    Logging.info("[EconomicEvents] Registered " .. #economicEvents.eventList .. " economic events")
    return true
end

-- =====================
-- DELAYED REGISTRATION
-- =====================
if g_RandomWorldEvents and g_RandomWorldEvents.registerEvent then
    registerEconomicEvents()
else
    local function delayedRegistration()
        if registerEconomicEvents() then
            Logging.info("[EconomicEvents] Successfully registered via delayed registration")
        end
    end

    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, delayedRegistration)

    Logging.info("[EconomicEvents] Added to pending registrations")
end

Logging.info("[EconomicEvents] Module loaded successfully")
-- =========================================================
-- Random World Events (version 2.0.0.5) - FS25
-- =========================================================
-- Wildlife / animal events for FS25
-- Category: "wildlife"  (matches self.events.wildlifeEvents setting key)
-- =========================================================
-- Author: TisonK
-- =========================================================

local animalEvents = {}

-- =====================
-- HELPERS
-- =====================

animalEvents.getFarmId = function()
    return g_currentMission and g_currentMission.player and g_currentMission.player.farmId or 0
end

-- Checks that at least one animal husbandry exists on the map.
-- Falls back to mission-exists check when g_currentMission.animalSystem is absent.
animalEvents.hasAnimals = function()
    if g_currentMission == nil then return false end
    if g_currentMission.animalSystem then
        local husbandries = g_currentMission.animalSystem:getHusbandries()
        return husbandries ~= nil and #husbandries > 0
    end
    return true -- allow trigger if we cannot determine animal count
end

-- =====================
-- WILDLIFE EVENT LIST
-- =====================
animalEvents.eventList = {

    -- 1. Bird flock descends on fields, reducing crop yield --------
    {
        name = "wildlife_bird_flock",
        minI = 1,
        func = function(intensity)
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.yieldMalus = 0.05 * intensity
            end
            return string.format(
                "A flock of birds is feeding on your crops! Yield -%.0f%%",
                intensity * 5
            )
        end
    },

    -- 2. Beneficial insects arrive, boosting fertilizer effect -----
    {
        name = "wildlife_beneficial_insects",
        minI = 1,
        func = function(intensity)
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.fertilizerBonus = 0.10 + 0.05 * intensity
            end
            return string.format(
                "Beneficial insects appear! Fertilizer effectiveness +%.0f%%!",
                (0.10 + 0.05 * intensity) * 100
            )
        end
    },

    -- 3. Wild animal stampede through fields — damage + yield hit --
    {
        name = "wildlife_stampede",
        minI = 2,
        func = function(intensity)
            local damage = math.random(300, 700) * intensity
            if g_currentMission and g_currentMission.addMoney then
                g_currentMission:addMoney(
                    -damage,
                    animalEvents.getFarmId(),
                    MoneyType.OTHER,
                    true
                )
            end
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.yieldMalus = 0.03 * intensity
            end
            return string.format(
                "Wild animals stampede through your fields! -€%d damage, yield -%.0f%%",
                damage, intensity * 3
            )
        end
    },

    -- 4. Predator spotted — livestock stressed, product penalty ----
    {
        name = "wildlife_predator_alert",
        minI = 2,
        func = function(intensity)
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.animalProductMalus = 0.1 * intensity
            end
            return string.format(
                "Predator spotted near the farm! Animals stressed, animal products -%.0f%%",
                intensity * 10
            )
        end
    },

    -- 5. Ideal conditions — livestock productivity bonus ----------
    {
        name = "wildlife_animal_product_bonus",
        minI = 1,
        func = function(intensity)
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.animalProductBonus = 0.1 * intensity
            end
            return string.format(
                "Ideal conditions for your livestock! Animal products +%.0f%%",
                intensity * 10
            )
        end
    },

    -- 6. Emergency vet visit — direct cash deduction ---------------
    {
        name = "wildlife_veterinary_visit",
        minI = 1,
        func = function(intensity)
            local cost = 500 + (intensity * 400)
            if g_currentMission and g_currentMission.addMoney then
                g_currentMission:addMoney(
                    -cost,
                    animalEvents.getFarmId(),
                    MoneyType.OTHER,
                    true
                )
            end
            return string.format("Emergency veterinary visit! -€%d", cost)
        end
    },

    -- 7. Regional disease scare — animal product price penalty -----
    {
        name = "wildlife_animal_disease_scare",
        minI = 2,
        func = function(intensity)
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.animalProductMalus = 0.12 * intensity
            end
            return string.format(
                "Disease scare in the region! Animal product prices -%.0f%%",
                intensity * 12
            )
        end
    },

    -- 8. Rabbit infestation damages crops — harvest penalty --------
    {
        name = "wildlife_rabbit_infestation",
        minI = 1,
        func = function(intensity)
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.yieldMalus = 0.04 * intensity
            end
            return string.format(
                "Rabbit infestation in your fields! Harvest -%.0f%%",
                intensity * 4
            )
        end
    },

    -- 9. Hunting season — local buyers pay more for livestock ------
    {
        name = "wildlife_hunting_season",
        minI = 1,
        func = function(intensity)
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.animalProductBonus = 0.08 * intensity
            end
            return string.format(
                "Hunting season brings buyers to the area! Livestock prices +%.0f%%",
                intensity * 8
            )
        end
    },

    -- 10. Wild bee swarm pollinates fields — crop yield bonus ------
    {
        name = "wildlife_bee_swarm",
        minI = 1,
        func = function(intensity)
            if g_RandomWorldEvents then
                g_RandomWorldEvents.EVENT_STATE.yieldBonus = 0.05 * intensity
            end
            return string.format(
                "Wild bees help pollinate your crops! Yield +%.0f%%",
                intensity * 5
            )
        end
    },
}

-- =====================
-- TICK HANDLER
-- Delivers periodic cash for animal product bonus/malus flags
-- every 60 in-game seconds.  numHusbandries scales the amount
-- so farms with more animals feel a bigger effect.
-- =====================
local function wildlifeTickHandler(rwe)
    if not g_currentMission then return end
    local s = rwe.EVENT_STATE
    local t = g_currentMission.time
    local lastTick = s.lastWildlifeTick or 0
    if t - lastTick < 60000 then return end
    s.lastWildlifeTick = t

    local farmId = g_currentMission.player and g_currentMission.player.farmId or 0
    if farmId == 0 then return end

    local numHusbandries = 1
    if g_currentMission.animalSystem then
        local husbandries = g_currentMission.animalSystem:getHusbandries()
        if husbandries then
            numHusbandries = math.max(1, #husbandries)
        end
    end

    local amount = 0
    if s.animalProductBonus then
        local bonus = math.floor(300 * s.animalProductBonus * numHusbandries)
        amount = amount + bonus
        Logging.info(string.format("[AnimalEvents] Product bonus: +€%d (%d husbandries)", bonus, numHusbandries))
    end
    if s.animalProductMalus then
        local malus = math.floor(250 * s.animalProductMalus * numHusbandries)
        amount = amount - malus
        Logging.info(string.format("[AnimalEvents] Product malus: -€%d (%d husbandries)", malus, numHusbandries))
    end

    if amount ~= 0 and g_currentMission.addMoney then
        g_currentMission:addMoney(amount, farmId, MoneyType.OTHER, false)
    end
end

-- =====================
-- REGISTER WILDLIFE EVENTS
-- =====================
local function registerAnimalEvents()
    if not g_RandomWorldEvents or not g_RandomWorldEvents.registerEvent then
        Logging.warning("[AnimalEvents] g_RandomWorldEvents not available yet")
        return false
    end

    for _, e in ipairs(animalEvents.eventList) do
        g_RandomWorldEvents:registerEvent({
            name         = e.name,
            category     = "wildlife",   -- maps to self.events.wildlifeEvents
            weight       = 1,
            duration     = { min = 15, max = 60 },
            minIntensity = e.minI,
            canTrigger   = function()
                -- Require a loaded mission; optionally require animals for animal-
                -- specific events, but crop events should fire regardless.
                return g_currentMission ~= nil
            end,
            onStart = e.func,
            onEnd = function()
                -- Clear all possible EVENT_STATE keys set by any wildlife event.
                if g_RandomWorldEvents then
                    local s = g_RandomWorldEvents.EVENT_STATE
                    s.yieldMalus         = nil
                    s.yieldBonus         = nil
                    s.fertilizerBonus    = nil
                    s.animalProductMalus = nil
                    s.animalProductBonus = nil
                    s.lastWildlifeTick   = nil
                end
                return "Wildlife event ended"
            end
        })
    end

    g_RandomWorldEvents:registerTickHandler("wildlifeEvents", wildlifeTickHandler)

    Logging.info("[AnimalEvents] Registered " .. #animalEvents.eventList .. " wildlife events")
    return true
end

-- =====================
-- DELAYED REGISTRATION
-- =====================
if g_RandomWorldEvents and g_RandomWorldEvents.registerEvent then
    registerAnimalEvents()
else
    local function delayedRegistration()
        if registerAnimalEvents() then
            Logging.info("[AnimalEvents] Successfully registered via delayed registration")
        end
    end

    if not RandomWorldEvents then RandomWorldEvents = {} end
    if not RandomWorldEvents.pendingRegistrations then
        RandomWorldEvents.pendingRegistrations = {}
    end
    table.insert(RandomWorldEvents.pendingRegistrations, delayedRegistration)

    Logging.info("[AnimalEvents] Added to pending registrations")
end

Logging.info("[AnimalEvents] Module loaded successfully")

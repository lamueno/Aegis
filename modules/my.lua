

-- Add the module to the tree
local mod = aegis
local me = {}
mod.my = me

------------------------------------------------------------------------------
-- Special Methods from Core.lua
------------------------------------------------------------------------------
me.myevents = {
    "ACTIONBAR_SLOT_CHANGED",
    "CHARACTER_POINTS_CHANGED",

    "UNIT_HEALTH",
    "UNIT_RAGE",
}

me.onloadcomplete = function()

    me.scanspellbook()
    me.scantalents()
    me.scanaction()
    
end

me.onupdate = function ()

    me.statsupdate()

end


me.onevent = function()

    if event == "UNIT_RAGE" and arg1 == "player" then
        me.prediction.rage_change_event()

    elseif event == "UNIT_HEALTH" and arg1 == "player" then
        me.prediction.health_change_event()

    elseif event == "CHARACTER_POINTS_CHANGED" then
        me.scantalents()

    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        me.scanaction()
    
    end
end

-----------------------------------------
--      Basic Character Stats          --
-----------------------------------------
me.rage = {}
me.health = {}

-- mod.my.class is the unlocalised lower case representation. e.g. "warrior", "rogue", no matter what locale you are in.
_, me.class = UnitClass("player")
me.class = string.lower(me.class)
_, me.race = UnitRace("player")
me.race = string.lower(me.race)
me.name = UnitName("player")

me.statsupdate = function()
    
    me.incombat = UnitAffectingCombat("player")
    
    me.health.health = UnitHealth("player")
    me.health.max = UnitHealthMax("player")
    me.health.pct = me.health.health / me.health.max * 100

    me.rage.rage = UnitMana("player")

    -- mod.my.armor is the effective armor armor after buffs
    _, me.armor = UnitArmor("player")

end

mod.my.buffed = function(buffname)
    return mod.libbuff.buffed(buffname, "player")
end


------------------------------------------------------------------------------
-- Spellbook and Talents
------------------------------------------------------------------------------
me.spellbook = {}
me.reversespellbook = {}

me.scanspellbook = function ()
    
    local spellid = 1
    while true do
        
        local name = GetSpellName(spellid, "spell")
        
        if not name then
            break
        else
            name = mod.string.reverselookup.spell[name]
            if name then
                me.spellbook[spellid] = name
                me.reversespellbook[name] = spellid
            end
        end
        
        spellid = spellid + 1
    end
end

me.scantalents = function()

    local name, rank, maxrank

    local function debug_talent()
        if rank > 0 then
           mod.output.trace("info", me, "talents", name.."("..rank.."/"..maxrank..")")
        end
    end
    
    -- Calculate the cost of Heroic Strike
    name, _, _, _, rank, maxrank = GetTalentInfo(1, 1)
    if rank > 0 then
        mod.db.spell["heroic_strike"].cost = 15 - rank
    end
    
	-- Calculate the rage retainment of Tactical Mastery
    name, _, _, _, rank, maxrank = GetTalentInfo(1, 5)
    me.tactical_mastery = rank * 5

    -- Calculate the cost of Thunderclap
    name, _, _, _, rank, maxrank = GetTalentInfo(1, 6)
    if rank > 0 then
        mod.db.spell["heroic_strike"].cost = 20 -  math.pow(2, rank-1)
    end

    --[[
    -- Check for Piercing Howl
	name, _, _, _, rank, maxrank = GetTalentInfo(2, 6)
    if rank > 0 then
        mod.db.settings["piercing_howl"] = true
	else
		mod.db.settings["piercing_howl"] = nil
    end
    
    -- Check for Last Stand
	name, _, _, _, rank, maxrank = GetTalentInfo(3, 6)
    if rank > 0 then
        mod.db.settings["last_stand"] = true
	else
		mod.db.settings["last_stand"] = nil
    end
    ]]

	-- Calculate the cost of Sunder Armor
    name, _, _, _, rank, maxrank = GetTalentInfo(3, 10)
    if rank > 0 then
        mod.db.spell["sunder_armor"].cost = 15 - rank
    end
    
    --[[
    -- Check for Concussion Blow
	name, _, _, _, rank, maxrank = GetTalentInfo(3, 14)
    if rank > 0 then
        mod.db.settings["concussion_blow"] = true
	else
		mod.db.settings["concussion_blow"] = nil
    end

    -- Check for Shield Slam
	name, _, _, _, rank, maxrank = GetTalentInfo(3, 17)
    if rank > 0 then
        mod.db.settings["shield_slam"] = true
	else
		mod.db.settings["shield_slam"] = nil
    end
    ]]

    me.talents = true
end

------------------------------------------------------------------------------
-- Action slots and Distance
------------------------------------------------------------------------------
me.actionslot = {}

me.scanaction = function()
    
    local slot = 1
    while slot <= 120 do

        local text = GetActionText(slot)
        local texture = GetActionTexture(slot)

        if texture then

            -- scan for revenge for more accurate cast judgement
            if not me.actionslot.revenge then
                if string.find(texture, "Ability_Warrior_Revenge") and text == nil then
                    me.actionslot.revenge = slot
                end
            end

            for distance, value in pairs(mod.db.distancetable) do
                if not me.actionslot[distance] then
                    for _, spell_texture in pairs(value) do
                        if string.find(texture, spell_texture) and text == nil then
                            me.actionslot[distance] = slot
                            break
                        end
                    end
                end
            end
        end
        
        slot = slot + 1
    end

    -- check if all required distance are found
    for distance, _ in pairs(mod.db.distancetable) do
        if not me.actionslot[distance] then
            mod.output.trace("warning", me, "scanaction", "Any skill at distance [" .. distance .. "] is not found in action bar.")
            return false
        end
    end

    -- mod.output.trace("info", me, "action", "All distance check spells are found.")
    return true
end

me.distance = function()

    if me.actionslot[5] and IsActionInRange(me.actionslot[5]) == 1 then
        return 5
    
    elseif me.actionslot[10] and IsActionInRange(me.actionslot[10]) == 1 then
        
        if me.actionslot[8] and IsActionInRange(me.actionslot[8]) == 0 then
            return 7
        end

        return 10
    
    elseif me.actionslot[25] and IsActionInRange(me.actionslot[25]) == 1 then
        return 25
    
    elseif me.actionslot[30] and IsActionInRange(me.actionslot[30]) == 1 then
        return 30 
    end

    return 999
end


------------------------------------------------------------------------------
-- Stance and Dance
------------------------------------------------------------------------------
me.activestance = function()
    for i = 1, 3 do
		local _, _, active = GetShapeshiftFormInfo(i)
		if active then
			return i
		end
	end
end

me.dansable = function()
    local settings = mod.db.settings.dance

    if (
        me.rage <= me.tactical_mastery + settings["rage_waste_allowed"]
        and settings["primary_stance"] > 0
    ) then
        return true
    else
        return false
    end
end


------------------------------------------------------------------------------
-- Equipment
------------------------------------------------------------------------------
me.weaponed = function()
    -- Detect if a suitable weapon (not a skinning knife/mining pick and not broken) is present
	local item = GetInventoryItemLink("player", 16)
	if item then
		local _, _, itemCode = strfind(item, "(%d+):")
		local itemName, itemLink, _, _, itemType = GetItemInfo(itemCode)
        
        if not (
            itemLink == "item:7005:0:0:0" 
            or itemLink == "item:2901:0:0:0" 
            or GetInventoryItemBroken("player", 16)
        ) then
			return true
		end
	end
	return false
end

me.shielded = function()
    -- Detect if a shield is present
	local item = GetInventoryItemLink("player", 17)
    if item then
		local _, _, itemCode = strfind(item, "(%d+):")
		local _, _, _, _, _, itemType = GetItemInfo(itemCode)
        
        if (
            itemType == mod.string.get("item_type", "shield") 
            and not GetInventoryItemBroken("player", 17)
        ) then
			return true
		end
	end
	return false
end

me.ranged_type = function()
    -- Detect if a ranged weapon is equipped and return type
	local item = GetInventoryItemLink("player", 18)
	if item then
		local _, _, itemCode = strfind(item, "(%d+):")
		local _, _, _, _, _, itemType = GetItemInfo(itemCode)
		return itemType
	end
	return nil
end

me.trinket = function()
    -- TODO
end


------------------------------------------------------------------------------
-- Rage/Health Tracking and Prediction
------------------------------------------------------------------------------
me.prediction = {}

me.prediction.rolling_average = function(old, deltaF, deltaT, interval, weight)
    
    -- set default parameter if not given
    local interval = interval or 15
    local weight = weight or 2

    return ( old * max(interval - weight * deltaT, 0) + weight * deltaF ) / interval
end

------------------------------------------------------------------------------
-- Rage

me.rage = {
    old = UnitMana("player"),
    last_gain = 0,
    gps_15 = 0,  -- short for gain per second by 15 seconds rolling 
    gps_5 = 0,  -- short for gain per second by 5 seconds rolling
    max_gps_15 = 0,
    max_gps_5 = 0
    
}

me.prediction.rage_change_event = function()

    local now = GetTime()
    local delta_rage = UnitMana("player") - me.rage.old
    me.rage.old = UnitMana("player")
    local delta_time = now - me.rage.last_gain
    me.rage.last_gain = now

    if delta_rage > 0 then

        me.rage.gps_15 = me.prediction.rolling_average(me.rage.gps_15, delta_rage, delta_time, 15)
        me.rage.gps_5 = me.prediction.rolling_average(me.rage.gps_5, delta_rage, delta_time, 5)

        if me.rage.gps_15 > me.rage.max_gps_15 then
            me.rage.max_gps_15 = me.rage.gps_15
        end

        if me.rage.gps_5 > me.rage.max_gps_5 then
            me.rage.max_gps_5 = me.rage.gps_5
        end

    elseif delta_time > 5 then
        me.rage.gps_15 = me.prediction.rolling_average(me.rage.gps_15, 0, 5, 15)

    elseif delta_time > 1.7 then
        me.rage.gps_5 = me.prediction.rolling_average(me.rage.gps_5, 0, 1.7, 5)

    end

    -- reset max gain when rage gain average dips below 0.1
    if me.rage.gps_15 < 0.1 and me.rage.max_gps_15 > 0 then
        me.rage.max_gps_15 = 0
    end

    if me.rage.gps_5 < 0.1 and me.rage.max_gps_5 > 0 then
        me.rage.max_gps_5 = 0
    end 

end

me.rage.prediction = function(in_seconds)
    return me.rage.rage + me.rage.gps_5 * in_seconds
end

------------------------------------------------------------------------------
-- Health

me.health = {
    old = UnitHealth("player"),
    last_gain = 0,
    gps_15 = 0,  -- short for gain per second by 15 seconds rolling 
    gps_5 = 0,  -- short for gain per second by 5 seconds rolling
    max_gps_15 = 0,
    max_gps_5 = 0,
    last_loss = 0,
    lps_15 = 0,  -- short for loss per second by 15 seconds rolling 
    lps_5 = 0,  -- short for loss per second by 5 seconds rolling
    max_lps_15 = 0,
    max_lps_5 = 0
    
}


me.prediction.health_change_event = function()

    local now = GetTime()
    local delta_health = UnitHealth("player") - me.health.old
    me.health.old = UnitHealth("player")

    if delta_health > 0 then
        local delta_time = now - me.health.last_gain
        me.health.last_gain = now

        me.health.gps_15 = me.prediction.rolling_average(me.health.gps_15, delta_health, delta_time, 15)
        me.health.gps_5 = me.prediction.rolling_average(me.health.gps_5, delta_health, delta_time, 5)

        if me.health.gps_15 > me.health.max_gps_15 then
            me.health.max_gps_15 = me.health.gps_15
        end

        if me.health.gps_5 > me.health.max_gps_5 then
            me.health.max_gps_5 = me.health.gps_5
        end

        if delta_time > 5 then
            me.health.gps_15 = me.prediction.rolling_average(me.health.gps_15, 0, 5, 15)

        elseif delta_time > 1.7 then
            me.health.gps_5 = me.prediction.rolling_average(me.health.gps_5, 0, 1.7, 5)
        end

    elseif delta_health < 0 then
        delta_health = -delta_health
        local delta_time = now - me.health.last_loss
        me.health.last_loss = now

        me.health.lps_15 = me.prediction.rolling_average(me.health.lps_15, delta_health, delta_time, 15)
        me.health.lps_5 = me.prediction.rolling_average(me.health.lps_5, delta_health, delta_time, 5)

        if me.health.lps_15 > me.health.max_lps_15 then
            me.health.max_lps_15 = me.health.lps_15
        end

        if me.health.lps_5 > me.health.max_lps_5 then
            me.health.max_lps_5 = me.health.lps_5
        end

        if delta_time > 5 then
            me.health.lps_15 = me.prediction.rolling_average(me.health.lps_15, 0, 5, 15)

        elseif delta_time > 1.7 then
            me.health.lps_5 = me.prediction.rolling_average(me.health.lps_5, 0, 1.7, 5)

        end

    end

    -- reset max when rolling average dips below 0.1
    if me.health.gps_15 < 0.1 and me.health.max_gps_15 > 0 then
        me.health.max_gps_15 = 0
    end

    if me.health.gps_5 < 0.1 and me.health.max_gps_5 > 0 then
        me.health.max_gps_5 = 0
    end

    if me.health.lps_15 < 0.1 and me.health.max_lps_15 > 0 then
        me.health.max_lps_15 = 0
    end

    if me.health.lps_5 < 0.1 and me.health.max_lps_5 > 0 then
        me.health.max_lps_5 = 0
    end 

end

me.health.prediction = function(in_seconds)
    return me.health.health + (me.health.gps_5 - me.health.lps_5) * in_seconds
end


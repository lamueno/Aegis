

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

    if event == "CHARACTER_POINTS_CHANGED" then
        me.scantalents()

    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        me.scanaction()
    
    end
end

-----------------------------------------
--      Basic Character Stats          --
-----------------------------------------
-- mod.my.class is the unlocalised lower case representation. e.g. "warrior", "rogue", no matter what locale you are in.
_, me.class = UnitClass("player")
me.class = string.lower(me.class)
_, me.race = UnitRace("player")
me.race = string.lower(me.race)
me.name = UnitName("player")

me.statsupdate = function()
    
    me.incombat = UnitAffectingCombat("player")
    me.health = UnitHealth("player")
    me.healthmax = UnitHealthMax("player")
    me.rage = UnitMana("player")

    -- mod.my.armor is the effective armor armor after buffs
    _, me.armor = UnitArmor("player")

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
        debug_talent()
    end
    
	-- Calculate the rage retainment of Tactical Mastery
    name, _, _, _, rank, maxrank = GetTalentInfo(1, 5)
    me.tactical_mastery = rank * 5
    debug_talent()

    -- Calculate the cost of Thunderclap
    name, _, _, _, rank, maxrank = GetTalentInfo(1, 6)
    if rank > 0 then
        mod.db.spell["heroic_strike"].cost = 20 -  math.pow(2, rank-1)
        debug_talent()
    end

    -- Check for Piercing Howl
	name, _, _, _, rank, maxrank = GetTalentInfo(2, 6)
    if rank > 0 then
        mod.db.settings["piercing_howl"] = true
        debug_talent()
	else
		mod.db.settings["piercing_howl"] = nil
    end
    
    -- Check for Last Stand
	name, _, _, _, rank, maxrank = GetTalentInfo(3, 6)
    if rank > 0 then
        mod.db.settings["last_stand"] = true
        debug_talent()
	else
		mod.db.settings["last_stand"] = nil
    end

	-- Calculate the cost of Sunder Armor
    name, _, _, _, rank, maxrank = GetTalentInfo(3, 10)
    if rank > 0 then
        mod.db.spell["sunder_armor"].cost = 15 - rank
        debug_talent()
    end
    
    -- Check for Concussion Blow
	name, _, _, _, rank, maxrank = GetTalentInfo(3, 14)
    if rank > 0 then
        mod.db.settings["concussion_blow"] = true
        debug_talent()
	else
		mod.db.settings["concussion_blow"] = nil
    end

    -- Check for Shield Slam
	name, _, _, _, rank, maxrank = GetTalentInfo(3, 17)
    if rank > 0 then
        mod.db.settings["shield_slam"] = true
        debug_talent()
	else
		mod.db.settings["shield_slam"] = nil
    end

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
            mod.output.print("Any skill at distance [" .. distance .. "] is not found in action bar.")
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
-- Inventory and Item functions
------------------------------------------------------------------------------
local function FindItem(item)
--[[
    Copied from SuperMacro.

    Find an item in your container bags or inventory. 
    If found in inventory, returns slot, nil, texture, count.
    If found in bags, returns bag, slot, texture, total count in all bags.
    Also works with item links. Alt-click on item to insert item link into macro.
    Ex. local bag,slot,texture,count = FindItem("Lesser Magic Essence");

]]
    if ( not item ) then return; end
    
    item = string.lower(ItemLinkToName(item))
    
    local link
    
    -- Look for equipments
	for i = 1,23 do
		link = GetInventoryItemLink("player",i)
		if link then
			if item == string.lower(ItemLinkToName(link)) then
				return i, nil, GetInventoryItemTexture('player', i), GetInventoryItemCount('player', i)
			end
		end
    end
    
    -- Look for bags
	local count, bag, slot, texture
    local totalcount = 0
    
    for i = 0, 4 do
        for j = 1, GetContainerNumSlots(i) do
            link = GetContainerItemLink(i, j)
            if link then
                if item == string.lower(ItemLinkToName(link)) then
                    bag, slot = i, j
					texture, count = GetContainerItemInfo(i, j)
					totalcount = totalcount + count
				end
            end
		end
	end
	return bag, slot, texture, totalcount;
end

local function ItemLinkToName(link)
    -- Copied from SuperMarco.
	if link then
   	    return gsub(link,"^.*%[(.*)%].*$","%1");
	end
end

local function UseItem(item)
	local bag,slot = FindItem(item)
	if ( not bag ) then return; end
	if ( slot ) then
		UseContainerItem(bag,slot) -- use, equip item in bag
		return bag, slot
	else
		UseInventoryItem(bag) -- use equipped item
		return bag
	end
end


------------------------------------------------------------------------------
-- Buff and Debuff
------------------------------------------------------------------------------
--[[
    `mod.my.buffed(buffname [, unit])` takes a localized buffname shown in the game client.
]]
me.buffed = function(buffname, unit)
    
    if not unit then unit = "player" end

    local tooltip = Aegis_Tooltip
    local headline = getglobal(tooltip:GetName().."TextLeft1")
    local slot

    -- Buff 
    for slot = 1, 32 do

        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetUnitBuff(unit, slot)
        local text = headline:GetText()
        tooltip:Hide()

        if text and strfind(text, buffname) then
            local _, count = UnitBuff(unit, slot)
            return "buff", slot, text, count
        elseif not text then
            break
        end
    end 

    -- Debuff
    for slot = 1, 32 do

        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetUnitDebuff(unit, slot)
        local text = headline:GetText()
        tooltip:Hide()

        if text and strfind(text, buffname) then
            local _, count, type = UnitDebuff(unit, slot)
            return "debuff", slot, text, count, type
        elseif not text then
            break
        end
    end 

    tooltip:Hide()
end


------------------------------------------------------------------------------
-- Rage/Health Tracking and Prediction
------------------------------------------------------------------------------

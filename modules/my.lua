

-- Add the module to the tree
local mod = aegis
local me = {}
mod.my = me


------------------------------------------------------------------------------
-- Basic Character Stats
------------------------------------------------------------------------------
-- mod.my.class is the unlocalised lower case representation. e.g. "warrior", "rogue", no matter what locale you are in.
_, me.class = UnitClass("player")
me.class = string.lower(me.class)
_, me.race = UnitRace("player")
me.race = string.lower(me.race)
me.name = UnitName("player")

me.rage = mod.libresource.Resource.new(UnitMana("player"))
me.health = mod.libresource.Resource.new(UnitHealth("player"))
me.health.max = UnitHealthMax("player")

mod.my.buffed = function(buffname)
  return mod.libbuff.buffed(buffname, "player")
end

------------------------------------------------------------------------------
-- Special Methods from Core.lua
------------------------------------------------------------------------------
me.myevents = {
	"ACTIONBAR_SLOT_CHANGED",
	"CHARACTER_POINTS_CHANGED",

	"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED",

	"UNIT_HEALTH",
	"UNIT_MAXHEALTH",
	"UNIT_RAGE",
}

me.onloadcomplete = function()

  me.scanspellbook()
  me.scantalents()
  me.scanaction()
  
end

me.onevent = function()

  local sequence = {
    me.trigger.talents,
    me.trigger.actionbar,
    me.trigger.rage,
    me.trigger.health,
    me.trigger.healthmax,
  }

  for _, trigger in sequence do
    if trigger() then break end
  end

end

me.onupdate = function()

	me.health:onupdate()
	me.rage:onupdate()

end


------------------------------------------------------------------------------
-- Event triggers
------------------------------------------------------------------------------
me.trigger = {}

me.trigger.rage = function()
  if event == "UNIT_RAGE" and arg1 == "player" then
    me.rage.now = UnitMana("player")
    me.rage:onevent()
    return true
  end
end

me.trigger.health = function()
  if event == "UNIT_HEALTH" and arg1 == "player" then
    me.health.now = UnitHealth("player")
    me.health.pct = me.health.now / me.health.max * 100
		
		if UnitAffectingCombat("player") then
			me.health:onevent()
		end
		
    return true
  end
end

me.trigger.healthmax = function()
  if event == "UNIT_MAXHEALTH" and arg1 == "player" then
    me.health.max = UnitHealthMax("player")
    me.health.pct = me.health.now / me.health.max * 100
    return true
  end
end

me.trigger.talents = function()
  if event == "CHARACTER_POINTS_CHANGED" then
    me.scantalents()
    return true
  end
end

me.trigger.actionbar = function()
  if event == "ACTIONBAR_SLOT_CHANGED" then
    me.scanaction()
    return true
  end
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








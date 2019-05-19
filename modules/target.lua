
-- Add the module to the tree
local mod = aegis
local me = {}
mod.target = me

------------------------------------------------------------------------------
-- Special Methods from Core.lua
------------------------------------------------------------------------------
me.myevents = {
  "UNIT_HEALTH",
  "PLAYER_TARGET_CHANGED"
}

me.onevent = function()

  local sequence = {
		me.trigger.reset,
		me.trigger.health,
	}

	for _, trigger in sequence do
		if trigger() then break end
	end
end

me.onupdate = function()
	if not me.health then
		me.health = mod.libresource.Resource.new(UnitHealth("target"))
		me.health.max = UnitHealthMax("target")
	end
	
	if UnitExists("target") then
		me.health:onupdate()
	end
end

------------------------------------------------------------------------------
-- Event triggers
------------------------------------------------------------------------------
me.trigger = {}

me.trigger.health = function()
	if event == "UNIT_HEALTH" and arg1 == "target" then
		if MobHealth3 then
      me.health.now, me.health.max, me.health.mh3 = MobHealth3:GetUnitHealth("target")
		end
		
		if not MobHealth3 or me.health.mh3 == false then
      me.health.now = UnitHealth("target")
      me.health.max = UnitHealthMax("target")
    end
		
		me.health.pct = me.health.now / me.health.max * 100
		me.health:onevent()
    return true
  end
end

me.trigger.reset = function()
	if event == "PLAYER_TARGET_CHANGED" and UnitExists("target") then
		me.health = mod.libresource.Resource.new(UnitHealth("target"))
		me.health.max = UnitHealthMax("target")
	end
end


------------------------------------------------------------------------------
-- Buff and Debuff
------------------------------------------------------------------------------
me.buffed = function(buffname)
  return mod.libbuff.buffed(buffname, "target")
end

  
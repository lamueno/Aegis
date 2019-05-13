
-- Add the module to the tree
local mod = aegis
local me = {}
mod.target = me

me.target = {}

------------------------------------------------------------------------------
-- Special Methods from Core.lua
------------------------------------------------------------------------------
me.myevents = {}

me.onupdate = function ()

    me.statsupdate()

end

me.statsupdate = function()

    me.name = UnitName("target")
    me.health = UnitHealth("target")
    me.healthmax = UnitHealthMax("target")

    me.target.name = UnitName("targettarget")
    me.target.health = UnitHealth("targettarget")
    me.target.healthmax = UnitHealthMax("targettarget")

end


------------------------------------------------------------------------------
-- Buff and Debuff
------------------------------------------------------------------------------
me.buffed = function(buffname)
    return mod.libbuff.buffed(buffname, "target")
end
    
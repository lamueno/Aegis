
-- Add the module to the tree
local mod = aegis
local me = {}
mod.combat = me

me.state = {
    dance = {},
    interrupt = {},
    overpower = {},
    revenge = {},

    autoattack = nil,
    disarmed = nil,
    incapacitated = nil,

    lastsunder = 0,
    conserved_rage = {},
    conserved_rage_total = 0,
}
me.cast = {}
me.use = {}

------------------------------------------------------------------------------
-- Special Methods from Core.lua
------------------------------------------------------------------------------
me.myevents = {
    "CHAT_MSG_COMBAT_SELF_MISSES",  -- 你未命中一个生物时触发
    "CHAT_MSG_SPELL_SELF_DAMAGE",  -- 你施放一个法术伤害时触发
    "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",  -- 当一个 buff (或可能的物品) 对对手的行为造成伤害... 如荆棘术.

    "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE",
    "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
    "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF",
    "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE",

    "CHAT_MSG_SPELL_SELF_DAMAGE",
    "CHAT_MSG_COMBAT_SELF_MISSES",

    "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
    "CHAT_MSG_SPELL_AURA_GONE_SELF",

    "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",

    "PLAYER_TARGET_CHANGED",
    
    "START_AUTOREPEAT_SPELL",
    "STOP_AUTOREPEAT_SPELL",

    -- "PLAYER_ENTER_COMBAT",
    -- "PLAYER_LEAVE_COMBAT",
    -- "PLAYER_REGEN_ENABLED",
    -- "PLAYER_REGEN_DISABLED",

    "CHAT_MSG_SPELL_FAILED_LOCALPLAYER",
}
me.onevent = function()

    
    local sequence = {
        me.trigger.autoattack,
        me.trigger.debuffed,
        me.trigger.interrupt,
        me.trigger.overpower,
        me.trigger.revenge,
    }

    for _, trigger in sequence do
        if trigger() then break end
    end
end

------------------------------------------------------------------------------
-- Event triggers
------------------------------------------------------------------------------
me.trigger = {}

me.trigger.overpower = function()
    if (event == "CHAT_MSG_COMBAT_SELF_MISSES"
	    or event == "CHAT_MSG_SPELL_SELF_DAMAGE"
        or event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"
    ) then
        for _, value in mod.string.get("combat", "overpower", "enable") do
            if string.find(arg1, value) then
                me.state.overpower = {flag="enabled", til=GetTime() + 4}
                return true
            end
        end
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        for _, value in mod.string.get("combat", "overpower", "disable") do
            if string.find(arg1, value) then
                me.state.overpower = {flag="disabled", til=nil}
                return true
            end
        end
    end
end

me.trigger.interrupt = function()
    if (event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE"
	    or event == "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF"
	    or event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF"
        or event == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"
    ) and mod.my.incombat then
        for mob, spell in string.gfind(arg1, mod.string.get("combat", "interrupt", "enable")) do
            local spell = mod.string.get("universal_spell", spell)
            if mob == UnitName("target") and spell ~= "." then
				me.state.interrupt = {flag="enabled", til=(GetTime() + spell.t / 1000)}
				return true
			end
        end
    
    elseif (
        event == "CHAT_MSG_SPELL_SELF_DAMAGE"
        and string.find(arg1, mod.string.get("combat", "interrupt", "success"))
    ) then
        me.state.interrupt = {flag="success", til=nil}
        return true
    
    elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        for _, value in mod.string.get("combat", "interrupt", "failure") do
            if string.find(arg1, value) then
                me.state.interrupt = {flag="failed", til=nil}
                return true
            end 
        end
    end
end

me.trigger.revenge = function()
    if event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" then
        
        for _, value in mod.string.get("combat", "revenge", "enable") do
            if string.find(arg1, value) then
                me.state.revenge = {flag="enabled", til=GetTime() + 4}
                return true
            end
        end
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        for _, value in mod.string.get("combat", "revenge", "disable") do
            if string.find(arg1, value) then
                me.state.revenge = {flag="disabled", til=nil}
                return true
            end
        end
    end
end

me.trigger.debuffed = function()
    if event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        
        for _, value in mod.string.get("combat", "disarmed", "enable") do
            if arg1 == value then
                me.state.disarmed = true
                return true
            end
        end

        for _, value in mod.string.get("combat", "fear", "enable") do
            if arg1 == value then
                me.state.fear = true
                return true
            end
        end

        for _, value in mod.string.get("combat", "incapacitated", "enable") do
            if arg1 == value then
                me.state.incapacitated = true
                return true
            end
        end

    elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then

        for _, value in mod.string.get("combat", "disarmed", "disable") do
            if arg1 == value then
                me.state.disarmed = nil
                return true
            end
        end

        for _, value in mod.string.get("combat", "fear", "disable") do
            if arg1 == value then
                me.state.fear = nil
                return true
            end
        end

        for _, value in mod.string.get("combat", "incapacitated", "disable") do
            if arg1 == value then
                me.state.incapacitated = nil
                return true
            end
        end
    end
end

me.trigger.autoattack = function()
    if event == "START_AUTOREPEAT_SPELL" then
        me.state.autoattack = true
        return true
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        me.state.autoattack = false
        return true
    end
end


------------------------------------------------------------------------------
-- Combat strategy
------------------------------------------------------------------------------
me.statuscheck = function()
    if (
        not UnitIsCivilian("target")
        and mod.my.class == "warrior"
        and mod.my.talents == true 
    ) then
        return true
    else
        mod.output.trace("info", me, "spell", "Combat Status check failed.")
        return false
    end
end

me.conserve_rage = function(name)

    local spell_cost = mod.db.spell[name].cost
    local spell_cd = mod.libspell.SpellReadyIn(name)
    local rage_gps = mod.my.rage.gps_5

    me.state.conserved_rage[name] = max(spell_cost * math.exp( -0.3 * spell_cd) - rage_gps, 0) or 0
    
    me.state.conserved_rage_total = 0
    for _, value in me.state.conserved_rage do
        me.state.conserved_rage_total = me.state.conserved_rage_total + value
        -- mod.output.trace("info", me, "combat", string.format("留怒 %s: %.1f (cd: %.1f)", name, value, spell_cd))
    end

end


------------------------------------------------------------------------------
-- mod.combat.use Section

me.use.antidisarm = function()
    local main = mod.db.settings["equipment"]["main_weapon"]
    local backup = mod.db.settings["equipment"]["antidisarm_weapon"]

    if (
        mod.db.settings["anti_disarm"]
        and main and backup
        and (me.state.disarmed or mod.db.disarmMobs[UnitName("target")])
    ) then
        UseItem(backup)
    else
        UseItem(main)
    end
end

me.use.shield = function()
    -- todo
    -- local name = mod.db.settings["equipment"]["shield"]
end


------------------------------------------------------------------------------
-- mod.combat.cast Section

me.cast.standardcast = function(name)

    local meta = mod.db.spell[name]

    -- Spell can be cast in current stance
    if meta.stance[mod.my.activestance()] == true then
        CastSpellByName(mod.string.get("spell", name))
        mod.output.tracespellcast(name)
        return true

    -- Dance to cast
    elseif me.state.dance.dancing ~= true and meta.dance ~= nil then
        me.state.dance.old = mod.my.activestance()
        me.state.dance.dancing = true
        CastShapeshiftForm(meta.dance)
        mod.output.tracespellcast(name, mod.db.stance[meta.dance])
        return true
    end

    -- Did nothing
    return
end

me.cast.stancedance = function()

    if not mod.my.dansable then return end
    
    local state= me.state.dance
    local primary = mod.db.settings.dance.primary_stance
    local spellname = mod.db.stance[primary]

    -- Reset to primary stance
    if primary ~= mod.my.activestance() and not state.dancing then
        if mod.libspell.SpellCanCast(spellname) then
            CastShapeshiftForm(primary)
            mod.output.tracespellcast(spellname)
            return true
        end
    end
end

me.cast.AutoAttack = function()
    if mod.db.settings["spell_option"]["autoattack"] and mod.my.incombat and not me.state.autoattack then
        AttackTarget()
        me.state.autoattack = true
    end
end


me.cast.BattleShout = function()

    local name = "battle_shout"

    if not mod.my.buffed(mod.string.get("spell", name))
        and mod.libspell.SpellCanCast(name)
        and mod.libspell.SpellReadyIn(name)    
    then
        if me.cast.standardcast(name) then
            return true
        end
    end

end

me.cast.BloodRage = function()

    local name = "blood_rage"

    if mod.libspell.SpellCanCast(name) and mod.libspell.SpellReadyIn(name) ==0 then
        if me.cast.standardcast(name) then
            return true
        end
    end

end

me.cast.Execute = function()

    if mod.libspell.SpellCanCast("execute") and mod.target.healthpct <= 20 and mod.libspell.SpellReadyIn("execute") == 0 then
        if me.cast.standardcast("execute") then
            return true
        end
    end

end

me.cast.HeroicStrike = function()

    if (mod.libspell.SpellCanCast("heroic_strike") and mod.libspell.SpellReadyIn("heroic_strike") == 0
        and mod.my.rage.rage >= mod.db.settings["spell_option"]["nextattack_rage"]
    ) then
        if me.cast.standardcast("heroic_strike") then
            return true
        end
    end

end

me.cast.Overpower = function()

    local state = me.state.overpower
    if state.flag == "enabled" then 
        if GetTime() > state.til then
            state.flag = "expired"
            state.til = nil
            mod.output.trace("info", me, "cast", "Overpower has expired.")
            return
        end
    else
        return
    end

    if mod.libspell.SpellCanCast("overpower") and mod.libspell.SpellReadyIn("overpower") == 0 then    
        if me.cast.standardcast("overpower") then
            return true
        end
    end 

end

me.cast.Pummel = function()

    local state = me.state.interrupt
    if state.flag == "enabled" then 
        if GetTime() > state.til then
            state.flag = "expired"
            state.til = nil
            mod.output.trace("info", me, "cast", "Too late to interrupt")
            return
        end
    else
        return
    end
    
    if mod.libspell.SpellCanCast("pummel") and mod.libspell.SpellReadyIn("pummel") == 0 then
        if me.cast.standardcast("pummel") then
            return true
        end
    end
    
end

me.cast.Revenge = function()

    local name = "revenge"
    local slot = mod.my.actionslot.revenge
    
    local state = me.state.revenge
    if state.flag == "enabled" then 
        if GetTime() > state.til then
            state.flag = "expired"
            state.til = nil
            -- mod.output.trace("info", me, "cast", "Revenge has expired.")
            return
        end
    else
        return
    end

    if mod.libspell.SpellReadyIn(name) == 0 then

        if slot then
            if IsUsableAction(slot) == 1 then
                if me.cast.standardcast(name) then
                    return true
                end
            end

        elseif mod.libspell.SpellCanCast(name) then
            if me.cast.standardcast(name) then
                return true
            end
        end
    end

end


me.cast.ShieldBash = function()

    local state = me.state.interrupt
    if state.flag == "enabled" then 
        if GetTime() > state.til then
            state.flag = "expired"
            state.til = nil
            mod.output.trace("info", me, "cast", "Too late to interrupt")
            return
        end
    else
        return
    end

    if mod.libspell.SpellCanCast("shield_bash") and mod.libspell.SpellReadyIn("shield_bash") == 0 then
        if me.cast.standardcast("shield_bash") then
            return true
        end
    end

end

me.cast.ShieldSlam = function ()

    local name = "shield_slam"

    if mod.libspell.SpellCanCast(name) and mod.libspell.SpellReadyIn(name) == 0 then
        CastSpellByName(mod.string.get("spell", name))
        mod.output.tracespellcast(name)
        return true

    elseif mod.libspell.SpellCanCast(name, nil, 1.5) and mod.libspell.SpellReadyIn(name) <= 1.5 then
        mod.output.trace("info", me, "cast", mod.string.get("translation", "Shield Slam is almost ready, wait"))
        return false
    end
end

me.cast.SunderArmor = function()

    local name = "sunder_armor"

    if not me.state.lastsunder then me.state.lastsunder = 0 end
    
    local _, _, _, count = mod.target.buffed(mod.string.get("spell", name))
    if count then
        if count > 2 or me.state.lastsunder + 25 > GetTime() then
            return
        end
    end

    if mod.libspell.SpellCanCast(name) and mod.libspell.SpellReadyIn(name) == 0 then

        if KLHTM_Sunder then
            KLHTM_Sunder()
        else me.cast.standardcast(name)
        end

        me.state.lastsunder = GetTime()
        mod.output.tracespellcast(name)
        return true
    end

end

me.cast.Taunt = function()

    local name = "taunt"

    if mod.libspell.SpellCanCast(name) and mod.libspell.SpellReadyIn(name) == 0 and UnitName("targettarget") ~= mod.my.name then
        if me.cast.standardcast(name) then
            return true
        end
    end

end

me.cast.ThunderClap = function()

    local name = "thunder_clap"

    if mod.libspell.SpellCanCast(name) and mod.libspell.SpellReadyIn(name) == 0 then
        if me.cast.standardcast(name) then
            return true
        end
    end

end

me.cast.DebuffTreat = function ()
    if buffed("龙血之痛：青铜", "player") then
		use("沙漏")
	end


end


me.cast.LifeSaving = function()

    local danger_health = 2000
    local danger_healthpct = 20

	if mod.my.health.health < danger_health or mod.my.health.pct < danger_healthpct then

		local item = mod.string.get("item", "Major Healthstone")
		if mod.libitem.ready(item) then
			mod.libitem.use(item)
			return true
		end

		local item = mod.string.get("item", "Major Healing Potion")
		if mod.libitem.ready(item) then
			mod.libitem.use(item)
			return true
		end

		local spell = "last_stand"
        if mod.libspell.SpellCanCast(spell) and mod.libspell.SpellReadyIn(spell) == 0 then
            if me.cast.standardcast(spell) then
                return true
            end
        end
    end
end


me.cast.charge = function()

end

me.cast.tank = function()
	local action_sequence = {
        me.cast.LifeSaving,
        me.cast.AutoAttack,
		me.cast.stancedance,
		me.cast.Revenge,
		me.cast.ShieldSlam,
		-- me.cast.ShieldBlock,
		me.cast.SunderArmor,
		me.cast.HeroicStrike,
		me.cast.BattleShout,
		me.cast.BloodRage,
	}
    
    me.conserve_rage("shield_slam")

	if me.statuscheck() then
		for _, spell in pairs(action_sequence) do
			if spell() then break end
		end
	end
end

me.cast.kick = function()

end

me.cast.pull = function()

end

me.cast.shoot = function()
    
    local name
    local ranged_type = mod.my.ranged_type
    local ranged_table = {
        [mod.string.get("item_type", "bow")] = mod.string.get("spell", "shoot_bow"),
        [mod.string.get("item_type", "crossbow")] = mod.string.get("spell", "shoot_crossbow"),
        [mod.string.get("item_type", "gun")] = mod.string.get("spell", "shoot_gun"),
        [mod.string.get("item_type", "thrown")] = mod.string.get("spell", "throw"),
    }

    if ranged_type and ranged_table[ranged_type] then
        name = ranged_table[ranged_type]
    else
        mod.output.trace("warning", me, "cast", "Cannot find correct ranged attack type")
        return false
    end

    if mod.libspell.SpellReadyIn(name) == 0 then
        CastSpellByName(name)
        mod.output.tracespellcast(name)
    end
    return true
end



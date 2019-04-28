

-- Add the module to the tree
local mod = aegis
local me = {}
mod.my = me

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
    "CHARACTER_POINTS_CHANGED",

    "CHAT_MSG_SPELL_FAILED_LOCALPLAYER",
}

me.onload = function()

    me.scanaction()

end

me.onevent = function()
end


me.actionslot = {}

me.scanaction = function()
    local slot = 1
    while slot <= 120 do
        local text = GetActionText(slot)
        local texture = GetActionTexture(slot)
        for distance, value in ipairs(me.distancetable) do
            if not me.actionslot[distance] then
                for _, spell_texture in value do
                    if string.find(texture, spell_texture) and (not text) then
                        me.actionslot[distance] = slot
                    end
                end
            end
        end
    end

    -- check if all required distance are found
    for distance, _ in ipair(me.distancetable) do
        if not me.actionslot[distance] then
            mod.output.print("Any skill at distance" .. distnce .. "is not found in action bar.")
            return false
        end
    end

    return true
end


me.distance = function()
    
    local max, min

    if not UnitCanAttack("player", "target") then
        min = 999
        max = 999

    elseif me.actionslot[5] and IsActionInRange(me.actionslot[5] == 1) then
        max = 5
        min = 0
    
    elseif me.actionslot[10] and IsActionInRange(me.actionslot[10]) == 1 then
        
        if me.actionslot[8] and IsActionInRange(me.actionslot[8]) == 0 then
            max = 7.9
            min = 5.1
        end

        max = 10
        min = 8
    
    elseif me.actionslot[25] and IsActionInRange(me.actionslot[25]) == 1 then
        max = 25
        min = 10.1
    
    elseif me.actionslot[30] and IsActionInRange(me.actionslot[30]) == 1 then
        max = 30
        min = 25.1 
    end

    return max, min
end

me.spell = mod.data.spell

me.talents = function()

    local rank
    
    --Calculate the cost of Heroic Strike based on talents
    _, _, _, _, rank = GetTalentInfo(1, 1)
    if rank > 0 then
        me.spell["heroic_strike"].cost = 15 - tonumber(rank)
        mod.out.debug(mod.string.get("talent", "imp_heroic_strike"))
    end
    
	--Calculate the rage retainment of Tactical Mastery
    _, _, _, _, rank = GetTalentInfo(1, 5)
    me.tactical_mastery = tonumber(rank) * 5
    mod.out.debug(mod.string.get("talent", "tactical_mastery"))

    --Check for Piercing Howl
	_, _, _, _, rank = GetTalentInfo(2, 6)
    if rank > 0 then
        me.spell["piercing_howl"].enabled = true
        mod.out.debug(mod.string.get("talent", "piercing_howl"))
	else
		me.spell["piercing_howl"].enabled = false
    end
    
	--Calculate the cost of Sunder Armor based on talents
    _, _, _, _, rank = GetTalentInfo(3, 10)
    if rank > 0 then
        me.spell["sunder_armor"].cost = 15 - tonumber(rank)
        mod.out.debug(mod.string.get("talent", "imp_sunder_armor"))
    end
    
    --Check for Death Wish
	_, _, _, _, rank = GetTalentInfo(2, 13)
    if rank > 0 then
        me.spell["death_wish"].enabled = true
        mod.out.debug(mod.string.get("talent", "death_wish"))
    else
        me.spell["death_wish"].enabled = false
	end
    
    --[[
    -- Check for Improved Berserker Rage
    _, _, _, _, rank = GetTalentInfo(2, 15)
	if currRank > 0 then
		Debug("强化狂暴之怒")
		FuryBerserkerRage = true
	else
		FuryBerserkerRage = false
	end
	--Check for Flurry
	_, _, _, _, rank = GetTalentInfo(2, 16)
	if currRank > 0 then
		Debug("乱舞")
		FuryFlurry = true
	else
		FuryFlurry = false
	end

	--Check for Bloodthirst
	_, _, _, _, rank = GetTalentInfo(2, 17)
	if currRank > 0 then
		Debug("嗜血")
		FuryBloodthirst =  true
	else
		FuryBloodthirst = false
	end
    ]]
 
	--Check for Shield Slam
	_, _, _, _, rank = GetTalentInfo(3, 17)
    if rank > 0 then
        me.spell["shield_slam"].enabled = true
        mod.out.debug(mod.string.get("talent", "shield_slam"))
	else
		me.spell["shield_slam"].enabled = false
	end
	if UnitRace("player") == RACE_ORC then
		Debug("血性狂暴")
		FuryRacialBloodFury = true
	else
		FuryRacialBloodFury = false
	end
	if UnitRace("player") == RACE_TROLL then
		Debug("狂暴")
		FuryRacialBerserking = true
	else
		FuryRacialBerserking = false
	end
	FuryTalents = true
end

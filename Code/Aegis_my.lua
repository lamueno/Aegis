

-- Add the module to the tree
local mod = aegis
local me = {}
mod.skills = me

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


-- Distance table records all skills which are relevant to distance.
me.distancetable = {
    [5] = {
        "Ability_Warrior_Sunder",
        "Ability_Warrior_DecisiveStrike",
        "Ability_ThunderBolt",
        "Ability_Warrior_Disarm",
        "INV_Gauntlets_04",
        "Ability_MeleeDamage",
        "Ability_Warrior_PunishingBlow",
        "Ability_Warrior_Revenge",
        "Ability_Gouge",
        "INV_Sword_48",
        "ability_warrior_savageblow",
        "INV_Shield_05",
        "Spell_Nature_Bloodlust"
    },
    [8] = {
        "Ability_Marksmanship",
        "Ability_Throw",
        "Ability_Warrior_Charge",
        "Ability_Rogue_Sprint"
    },
    [10] = {
        "Ability_GolemThunderClap",
    },
    [25] = {
        "Ability_Warrior_Charge",
        "Ability_Rogue_Sprint"
    },
    [30] = {
        "Ability_Marksmanship",
        "Ability_Throw",
    }
}

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




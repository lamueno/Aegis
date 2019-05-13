
-- Add the module to the tree
local mod = aegis
local me = {}
mod.db = me

me.settings = {}
me.disarmMobs = {}
me.runaways = {}

------------------------------------------------------------------------------
-- Intialize setting db and load saved settings.
------------------------------------------------------------------------------
-- Load settings from Savedvariables or initialize the settings table if it does not exist.
local function Aegis_Setup()

    if AegisDB == nil then
        AegisDB = {}
    end

    if AegisDB["settings"] == nil then
        AegisDB["settings"] = me.default_settings
    else
        for index, value in pairs(AegisDB["settings"]) do
            me.settings[index] = value
        end
    end

    if AegisDB["disarmMobs"] == nil then
        AegisDB["disarmMobs"] = me.disarmMobs
    else
        for index, value in pairs(AegisDB["disarmMobs"]) do
            me.disarmMobs[index] = value
        end
    end

    if AegisDB["runaways"] == nil then
        AegisDB["runaways"] = me.runaways
    else
        for index, value in pairs(AegisDB["runaways"]) do
            me.runaways[index] = value
        end
    end

end

me.myevents = {"ADDON_LOADED"}

me.onevent = function ()
    Aegis_Setup()
end




--[[
Default settings

This part of settings will be written into SavedVariables and loaded afterwards.
It can be called by `mod.db.settings`
]]
-- 
me.default_settings = {
    ["enabled"] = true,
    ["debug"] = true,  -- Enabled while under production
    ["dance"] = {
        --[[
            primary_stance: 
            Dance Disabled = 0;
            Battle Stance = 1;
            Defensive Stance = 2;
            Berserker Stance = 3;
        ]]
        ["primary_stance"] = 1,
        ["rage_waste_allowed"] = 25,
    },
    ["disabledspell"] = {
        --[[
        stores disabled spells here. The tree will look like:
        {
            ["death_wish"] = true,
            ["hamstring"] = true,
        }
        ]]
    },
    ["equipment"] = {},
    ["spell_option"] = {
        ["autoattack"] = true,
        ["bloodrage_health_pct"] = 70,
        ["deathwish_health_pct"] = 60,
        ["hamstring_health_pct"] = 20, 
        ["nextattack_rage"] = 20, 
    },
}


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
        "Ability_Warrior_Savageblow",
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

--[[
All skills meta data. This table 
]] 
me.spell = {
    ["battle_shout"] = 
    {
        cost = 10,
        gcd = true,
        stance = {[1] = true, [2] = true, [3] = true},
    },
    ["battle_stance"] = {gcd = true},
    ["berserker_rage"] =
    {
        cost = 0,
        gcd = true,
        stance = {[3] = true},
        dance = 3,
    },
    ["berserker_stance"] = {gcd = true},
    ["blood_rage"] = {
        stance = {[1] = true, [2] = true, [3] = true},
    },
    ["blood_thirst"] = 
    {
        cost = 30,
        distance = {min = 0, max = 5},
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
    },
    ["challenging_shout"] = 
    {
        cost = 5,
        distance = {min = 0, max = 10},
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
    },
    ["charge"] = 
    {
        cost = 0,
        combat = false,
        distance = {min = 8, max = 25},
        gcd = true,
        stance = {[1] = true},
        dance = 1,
    },
    ["cleave"] = 
    {
        cost = 20,
        distance = {min = 0, max = 5},
        nextattack = true,
        stance = {[1] = true, [2] = true, [3] = true},
        weaponed = true,
    },
    ["concussion_blow"] = 
    {
        cost = 15,
        distance = {min = 0, max = 5},
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
        weaponed = true,
    },
    ["death_wish"] =
    {
        cost = 10,
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
    },
    ["defensive_stance"] = {gcd = true},
    ["demoralizing_shout"] = 
    {
        cost = 10,
        distance = {min = 0, max = 10},
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
    },
    ["disarm"] = 
    {
        cost = 20,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[2] = true},
        dance = 2,
    },
    ["execute"] = 
    {
        cost = 15,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[1] = true, [3] = true},
        dance = 3,
        weaponed = true,
    },
    ["hamstring"] = 
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[1] = true, [3] = true},
        dance = 1,
        weaponed = true,
    },
    ["heroic_strike"] =
    {
        cost = 15,
        distance = {min = 0, max = 5},
        gcd = false,
        nextattack = true,
        stance = {[1] = true, [2] = true, [3] = true},
        weaponed = true,
    },
    ["intercept"] = 
    {
        cost = 10,
        distance = {min = 8, max = 25},
        gcd = true,
        stance = {[3] = true},
    },
    ["intimidating_shout"] =
    {
        cost = 25,
        distance = {min = 0, max = 10},
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
    },
    ["last_stand"] = {
        stance = {[1] = true, [2] = true, [3] = true},
    },
    ["mocking_blow"] = 
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[1] = true},
        dance = 1,
        weaponed = true,
    },
    ["mortal_strike"] = 
    {
        cost = 30,
        distance = {min = 0, max = 5},
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
        weaponed = true,
    },
    ["overpower"] =
    {
        cost = 5,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[1] = true},
        dance = 1,
        weaponed = true,
    },
    ["pummel"] = 
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[3] = true},
        dance = 3,
    },
    ["recklessness"] = {
        stance = {[3] = true},
    },
    ["rend"] =
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[1] = true, [2] = true},
        dance = 1,
        weaponed = true,
    },
    ["revenge"] =
    {
        cost = 5,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[2] = true},
        dance = 2,
        weaponed = true,
    },
    ["shield_bash"] =
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[1] = true, [2] = true},
        dance = 1,
        shielded = true,
    },
    ["shield_block"] =
    {
        cost = 10,
        stance = {[2] = true},
        dance = 2,
        shielded = true,
    },
    ["shield_slam"] =
    {
        cost = 20,
        distance = {min = 0, max = 5},
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
        shielded = true,
    },
    ["shield_wall"] = 
    {
        gcd = true,
        stance = {[2] = true},
        dance = 2,
        shielded = true,
    },
    ["sunder_armor"] = 
    {
        cost = 15,
        distance = {min = 0, max = 5},
        stance = {[1] = true, [2] = true, [3] = true},
        gcd = true,
        weaponed = true,
    },
    ["sweeping_strikes"] = {
        stance = {[1] = true, [2] = true, [3] = true},
    },
    ["taunt"] = 
    {
        cost = 0,
        distance = {min = 0, max = 5},
        stance = {[2] = true},
        dance = 2,
    },
    ["thunder_clap"] =
    {
        cost = 20,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[1] = true, [3] = true},
        dance = 1,
        weaponed = true,
    },
    ["whirlwind"] = 
    {
        cost = 25,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {[3] = true},
        dance = 3,
        weaponed = true,
    },
}

me.stance = {
    [1] = "battle_stance",
    [2] = "defensive_stance",
    [3] = "berserker_stance"
}

-- Add the module to the tree
local mod = aegis
local me = {}
mod.data = me


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

-- All skills meta 
me.spell = {
    ["battle_shout"] = 
    {
        cost = 10,
        gcd = true,
        stance = {1, 2, 3}
    },
    ["berserker_rage"] =
    {
        cost = 0,
        gcd = true,
        stance = {3}
    },
    ["bloodrage"] = {},
    ["bloodthirst"] = 
    {
        cost = 30,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 2, 3},
    },
    ["challenging_shout"] = 
    {
        cost = 5,
        distance = {min = 0, max = 10},
        gcd = true,
    },
    ["charge"] = 
    {
        cost = 0,
        combat = false,
        distance = {min = 8, max = 25},
        gcd = true,
        stance = {1}
    },
    ["cleave"] = 
    {
        cost = 20,
        distance = {min = 0, max = 5},
        nextattack = true,
        stance = {1, 2, 3},
        weapon = true,
    },
    ["concussion_blow"] = 
    {
        cost = 15,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 2, 3},
        weapon = true,
    },
    ["death_wish"] =
    {
        cost = 10,
        gcd = true,
        stance = {1, 2, 3}
    },
    ["demoralizing_shout"] = 
    {
        cost = 10,
        distance = {min = 0, max = 10},
        gcd = true,
    },
    ["disarm"] = 
    {
        cost = 20,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {2},
    },
    ["execute"] = 
    {
        cost = 15,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 3},
        weapon = true,
    },
    ["hamstring"] = 
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 3},
        dance = 1,
        weapon = true,
    },
    ["heroic_strike"] =
    {
        cost = 15,
        distance = {min = 0, max = 5},
        gcd = false,
        nextattack = true,
        stance = {1, 2, 3},
        weapon = true,
    },
    ["intercept"] = 
    {
        cost = 10,
        distance = {min = 8, max = 25},
        gcd = true,
        stance = {3},
    },
    ["intimidating_shout"] =
    {
        cost = 25,
        distance = {min = 0, max = 10},
        gcd = true,
    },
    ["last_stand"] = {},
    ["mocking_blow"] = 
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1},
        weapon = true,
    },
    ["mortal_strike"] = 
    {
        cost = 30,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 2, 3},
        weapon = true,
    },
    ["overpower"] =
    {
        cost = 5,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1},
        weapon = true,
    },
    ["pummel"] = 
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {3},
    },
    ["recklessness"] = {},
    ["rend"] =
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 2},
        dance = 1,
        weapon = true,
    },
    ["revenge"] =
    {
        cost = 5,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {2},
        weapon = true,
    },
    ["shield_bash"] =
    {
        cost = 10,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 2},
        shield = true,
    },
    ["shield_block"] =
    {
        cost = 10,
        stance = {2},
        shield = true,
    },
    ["shield_slam"] =
    {
        cost = 20,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 2, 3},
        shield = true,
    },
    ["shield_wall"] = 
    {
        gcd = true,
        stance = {2},
        shield = true,
    },
    ["sunder_armor"] = 
    {
        cost = 15,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 2, 3},
        weapon = true,
    },
    ["sweeping_strikes"] = {},
    ["taunt"] = 
    {
        cost = 0,
        distance = {min = 0, max = 5},
        stance = {2},
    },
    ["thunder_clap"] =
    {
        cost = 20,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {1, 3},
        dance = 1,
        weapon = true,
    },
    ["whirlwind"] = 
    {
        cost = 25,
        distance = {min = 0, max = 5},
        gcd = true,
        stance = {3},
        weapon = true,
    },
}

-- Values are {Page, Talent}
me.talentinfo = 
{	
	imp_heroicstrike = {1, 1},
    tacticalmastery = {1, 5},
    sweepingstrike = {1, 13},
	piercinghowl = {2, 6},
	imp_execute = {2, 10},
    deathwish = {2, 13},
    imp_berserkerrage = {2, 15},
    flurry = {2, 16},
    bloodthirst = {2, 17},
    imp_sunder = {3, 10},
    shield_slam = {3, 17},
}
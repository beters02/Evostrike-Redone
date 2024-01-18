local DEFAULT_BUY_MENU_ABILITIES_PRIMARY = {
    "dash"
}

local DEFAULT_BUY_MENU_ABILITIES_SECONDARY = {
    "longFlash", "heGrenade", "smokeGrenade", "molly"
}

local GameOptions = {
    ROUND_LENGTH = 85,
    BOMB_PLANT_ROUND_LENGTH = 40,
    BUY_MENU_CAN_PURCHASE_LENGTH = 15,
    MAX_ROUND_WIN = 13,
    OVERTIME_ROUND_WIN = 5,

    STARTING_SECONDARY_WEAPON_ATTACKER = "glock17",
    STARTING_SECONDARY_WEAPON_DEFENDER = "hkp30",

    STARTING_MONEY = 800,

    KILLED_TEAMMATE_MONEY_DEC = 300
}

GameOptions.Enum = {
    KILL_MONEY_GAINED = {
        default = 300,
        intervention = 100,
        vityaz = 400,
        knife = 1000
    },
    WEAPON_COST = {
        default = 200,

        ak103 = 2900,
        acr = 3100,
        glock17 = 200,
        hkp30 = 200,
        intervention = 4750,
        vityaz = 1800,
        deagle = 800,
    },
    ABILITY_COST = {
        default = 400,

        dash = 400,
        longflash = 400,
        hegrenade = 500,
        molly = 500,
        smokegrenade = 300
    },
    ABILITY_MAX_AMOUNT = {
        default = 1,

        dash = 2,
        longflash = 2,
        molly = 1,
        smokegrenade = 2,
        hegrenade = 1
    },
    EQUIPMENT_MAX_AMOUNT = {
        lightshield = 25,
        heavyshield = 50,
    },
    EQUIPMENT_COST = {
        lightshield = 400,
        heavyshield = 1000,
        defuser = 400
    },
    BUY_MENU_ATTACKER = {
        rifles = {ak103 = true, vityaz = true},
        pistols = {glock17 = true, deagle = true},
        primaryAbilities = DEFAULT_BUY_MENU_ABILITIES_PRIMARY,
        secondaryAbilities = DEFAULT_BUY_MENU_ABILITIES_SECONDARY,
        equipment = {lightshield = true, heavyshield = true}
    },
    BUY_MENU_DEFENDER = {
        rifles = {acr = true, vityaz = true},
        pistols = {hkp30 = true, deagle = true},
        primaryAbilities = DEFAULT_BUY_MENU_ABILITIES_PRIMARY,
        secondaryAbilities = DEFAULT_BUY_MENU_ABILITIES_SECONDARY,
        equipment = {lightshield = true, heavyshield = true, defuser = true}
    },

    WEAPON_PROPERTIES = {},
    ABILITY_PROPERTIES = {},
}

return GameOptions
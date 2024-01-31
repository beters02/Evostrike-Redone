export type PlayerData = {
    --inventory: {case: table, skin: table, equipped: table},
    options: table,
    states: table,
    pstats: table,
    ownedItems: {case: table, key: table, skin: table, equipped: table}
}

local Shared = {def = {states = {invMod_init = false}}}

-- Variables for each Inventory Def
Shared.defVar = {
    inventory = {clientReadOnly = true},
    owendItems = {clientReadOnly = true},
    options = {clientReadOnly = false},
    states = {clientReadOnly = true},
    pstats = {clientReadOnly = true},
    economy = {clientReadOnly = true}
}

-- [[ PLAYER OWNED ITEMS INFORMATION ]]

-- case & keys: "caseName"

-- skins: "weaponName_modelName_skinName_uuid"
-- all default skins have a UUID of 0

-- skin ex:
--      "ak103_ak103_default_0"
--      "ak103_ak103_knight_13212313"
--      "knife_default_default_0"
--      "knife_karambit_sapphire_1231313"

Shared.def.ownedItems = {case = {}, key = {}, skin = {}, states = {}, equipped = {
    ak47 = "ak47_ak47_default_0",
    glock17 = "glock17_glock17_default_0",
    knife = "knife_default_default_0",
    vityaz = "vityaz_vityaz_default_0",
    ak103 = "ak103_ak103_default_0",
    acr = "acr_acr_default_0",
    deagle = "deagle_deagle_default_0",
    intervention = "intervention_intervention_default_0",
    hkp30 = "hkp30_hkp30_default_0",
}}

--[OPTIONS]
Shared.def.options = {
    crosshair = {
        red = 0,
        blue = 255,
        green = 255,
        gap = 5,
        size = 5,
        thickness = 2,
        dot = false,
        dynamic = false,
        outline = false
    },

    camera = {
        vmX = 0,
        vmY = 0,
        vmZ = 0,
        FOV = 75,
    },

    keybinds = {
        primaryWeapon = "One",
        secondaryWeapon = "Two",
        ternaryWeapon = "Three",
        bombWeapon = "Five",
        primaryAbility = "F",
        secondaryAbility = "V",
        interact = "E",
        jump = "Space",
        crouch = "LeftControl",
        inspect = "T",
        equipLastEquippedWeapon = "Q",
        drop = "G",

        aimToggle = 1, -- 1 = toggle, 0 = hold
        crouchToggle = 0
    }
}

Shared.def.pstats = {
    kills = 0,
    deaths = 0,
    wins = 0,
    losses = 0,
    mapWins = {},
}

Shared.def.economy = {
    strafeCoins = 0,
    premiumCredits = 0,
    xp = 0
}

return Shared
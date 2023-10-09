export type PlayerData = {
    inventory: {case: table, skin: table, equipped: table},
    options: table,
    states: table,
    pstats: table
}

local Shared = {}

Shared.def = {
    inventory = {case = {}, skin = {}, equipped = {
        ak47 = "default",
        glock17 = "default",
        knife = "default_default",
        vityaz = "default",
        ak103 = "default",
        usp = "default",
        acr = "default",
        deagle = "default",
        intervention = "default",
        hkp30 = "default",
    }},
    
    options = {
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
    },
    
    states = {
        isQueueProcessing = false,
        isQueueAdding = false,
        isQueueRemoving = false,
        isQueueDisabled = false,
        hasBeenGivenAdminInventory = false, -- applied in adminModifications
        hasBeenGivenInventoryReset1 = false,
    },

    pstats = {
        kills = 0,
        deaths = 0,
        totaldamage = 0,
        wins = 0
    },

    economy = {
        strafeCoins = 0,
        premiumCredits = 0,
        xp = 0
    }
}

Shared.defVar = {
    inventory = {clientReadOnly = true},
    options = {clientReadOnly = false},
    states = {clientReadOnly = true},
    pstats = {clientReadOnly = true},
    economy = {clientReadOnly = true}
}

return Shared
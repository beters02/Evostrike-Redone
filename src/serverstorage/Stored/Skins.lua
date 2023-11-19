local Strings = require(game:GetService("ReplicatedStorage"):WaitForChild("lib"):WaitForChild("fc_strings"))

-- Skin Object Type
export type OSkin = {
    name: string,
    price_sc: number?,
    price_pc: number?,
    sell_sc: number?
}

-- Skin Object Creation
local OSkin = {new = function(prop)
    prop = prop or {}
    local _oskin = {
        name = "Skin",
        price_pc = 10,
        price_sc = 100,
        sell_sc = false
    }:: OSkin
    for i, v in pairs(prop) do
        _oskin[i] = v
    end
    return _oskin
end}

-- [[ SKIN DEFS ]]
local Skins = {
    ak103 = {
        hexstripe = OSkin.new({name = "Hexstripe", index = "hexstripe", weapon = "ak103", price_pc = 100, price_sc = 1000, sell_sc = 750}),
        knight = OSkin.new({name = "Knight", index = "knight", weapon = "ak103", price_pc = 600, price_sc = 6000, sell_sc = 4500})
    },
    glock17 = {
        hexstripe = OSkin.new({name = "Hexstripe", index = "hexstripe", weapon = "glock17", price_pc = 75, price_sc = 750, sell_sc = 562}),
        curvedPurple = OSkin.new({name = "Curved Purple", index = "curvedPurple", weapon = "glock17", price_pc = 300, price_sc = 3000, sell_sc = 2250}),
        matteObsidian = OSkin.new({name = "Matte Obsidian", index = "matteObsidian", weapon = "glock17", price_pc = 800, price_sc = 8000, sell_sc = 6000})
    },
    vityaz = {
        olReliable = OSkin.new({name = "Ol' Reliable", index = "olReliable", weapon = "vityaz", price_pc = 100, price_sc = 1000, sell_sc = 750})
    },
    hkp30 = {
        curvedPurple = OSkin.new({name = "Curved Purple", index = "curvedPurple", weapon = "hkp30", price_pc = 300, price_sc = 3000, sell_sc = 2250}),
    }
}

-- [[ SKINS MODULE ]]
local SkinsModule = {
    GetSkinFromString = function(str)
        local skin = Strings.convertPathToInstance(str, Skins, false, "_")
        skin.inventoryKey = str
        return skin
    end,

    Skins = Skins
}

return SkinsModule
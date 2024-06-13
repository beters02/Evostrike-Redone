--TODO: create folder called "ShopItems" and stores Cases, Keys and Skins

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
        hexstripe = {           name = "Hexstripe",       rarity = "Common",        price_pc = 200,    price_sc = 2000,    sell_sc = 1500},
        knight = {              name = "Knight",          rarity = "Epic",          price_pc = 600,       price_sc = 6000,    sell_sc = 4500}
    },

    glock17 = {
        hexstripe = {           name = "Hexstripe",       rarity = "Common",        price_pc = 75,     price_sc = 750,     sell_sc = 562},
        curvedPurple = {        name = "Curved Purple",   rarity = "Rare",          price_pc = 200,    price_sc = 2000,    sell_sc = 1500},
        matteObsidian = {       name = "Matte Obsidian",  rarity = "Epic",          price_pc = 500,    price_sc = 5000,    sell_sc = 3750},
    },

    vityaz = {
        olReliable = {          name = "Ol' Reliable",    rarity = "Common",        price_pc = 150,    price_sc = 1500,    sell_sc = 1125},
    },

    hkp30 = {
        curvedPurple = {        name = "Curved Purple",   rarity = "Rare",          price_pc = 200,    price_sc = 2000,    sell_sc = 1500},
    },

    acr = {
        jade = {                name = "Jade",            rarity = "Common",        price_pc = 100,    price_sc = 1000,    sell_sc = 700}
    },

    knife = {
        m9bayonet = {
            default = {         name = "Default",         rarity = "Legendary",     price_pc = 1500,   price_sc = 15000,   sell_sc = 11250},
            ruby = {            name = "Ruby",            rarity = "Legendary",     price_pc = 1850,   price_sc = 18500,   sell_sc = 13875},
            sapphire = {        name = "Sapphire",        rarity = "Legendary",     price_pc = 1850,   price_sc = 18500,   sell_sc = 13875},
            matteObsidian = {   name = "Matte Obsidian",  rarity = "Legendary",     price_pc = 1850,   price_sc = 18500,   sell_sc = 13875},
        },
        karambit = {
            default = {         name = "Default",         rarity = "Legendary",     price_pc = 1500,   price_sc = 15000,   sell_sc = 11250},
            ruby = {            name = "Ruby",            rarity = "Legendary",     price_pc = 1850,   price_sc = 18500,   sell_sc = 13875},
            sapphire = {        name = "Sapphire",        rarity = "Legendary",     price_pc = 1850,   price_sc = 18500,   sell_sc = 13875},
            matteObsidian = {   name = "Matte Obsidian",  rarity = "Legendary",     price_pc = 1850,   price_sc = 18500,   sell_sc = 13875},
            fractal7 = {        name = "Fractal",         rarity = "Legendary",     price_pc = 1850,   price_sc = 18500,   sell_sc = 13875},
        },
        butterfly = {
            default = {         name = "Default",         rarity = "Legendary",     price_pc = 1500,   price_sc = 15000,   sell_sc = 11250},
            twirl = {           name = "Twirl",           rarity = "Legendary",     price_pc = 1850,   price_sc = 18500,   sell_sc = 13875},
        }
    }
}

-- [[SKINDEF -> OSKIN]]
for wepStr, wep in pairs(Skins) do
    if wepStr == "knife" then
        for modelStr, model in pairs(wep) do
            for skinStr, skin in pairs(model) do
                skin.index = skinStr
                skin.weapon = "knife"
                skin.model = modelStr
                Skins.knife[modelStr][skinStr] = OSkin.new(skin)
            end
        end
        continue
    end
    for skinStr, skin in pairs(wep) do
        skin.index = skinStr
        skin.weapon = wepStr
        Skins[wepStr][skinStr] = OSkin.new(skin)
    end
end

-- [[ SKINS MODULE ]]
local SkinsModule = {
    GetSkinFromString = function(str)
        local skin = Strings.convertPathToInstance(str, Skins, false, "_")
        skin.inventoryKey = str
        return skin
    end,

    ConvertShopSkinStrToInvStr = function(str)  -- UUID needs to be added on own
        -- shopstr = weapon_skin or knife_model_skin
        local split = str:split("_")
        if #split == 3 then
            return str
        end
        return split[1] .. "_" .. str -- weapon_weapon_skin
    end,

    Skins = Skins
}

SkinsModule.GetSkinFromInvString = function(str)
    local split = str:split("_")
    local shopstr = split[2] .. "_" .. split[3]
    if split[1] == "knife" then
        shopstr = "knife_" .. shopstr
    end
    return Strings.convertPathToInstance(shopstr, Skins, false, "_")
end

function SkinsModule.GetSkinRarityFromInvString(str)
    local split = str:split("_")
    if split[1] == "knife" then
        return Skins.knife[split[2]][split[3]].rarity
    end
    return Skins[split[2]][split[3]].rarity
end

return SkinsModule
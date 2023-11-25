type Array<T> = {[number]: T}
export type VCaseLootTable = { common: Array<string>, rare: Array<string>, epic: Array<string>, legendary: Array<string> }
export type OCase = { name: string, loot: VCaseLootTable, price_pc: number?, price_sc: number?, sell_sc: number? }

-- Knives found in all cases
local function getDefaultLegendaries()
    return {
        "knife_karambit_default", "knife_karambit_sapphire", "knife_karambit_ruby", "knife_karambit_matteObsidian",
        "knife_m9bayonet_default", "knife_m9bayonet_sapphire", "knife_m9bayonet_ruby", "knife_m9bayonet_matteObsidian"
    }
end

-- [[ RARITY CONFIGURATION ]]
local rarityInfo = { -- in order from most rare to least
    {str = "legendary", chancePercent = 2},
    {str = "epic", chancePercent = 8},
    {str = "rare", chancePercent = 27},
    {str = "common", chancePercent = 63}
}

function getRarityFromNumber(number) -- number must be 1-100
    for i, v in pairs(rarityInfo) do
        if i == #rarityInfo then
            return "common"
        end
        if number >= 100 - v.chancePercent then
            return v.str
        end
    end
end

-- [[ CASE OBJECT ]]
local OCase = {new = function(prop)
    prop = prop or {}
    local _ocase = {
        name = "Case_Case",
        price_pc = 10,
        price_sc = 100,
        sell_sc = 65,
        loot = {common = {}, rare = {}, epic = {}, legendary = getDefaultLegendaries()}
    }:: OCase
    for i, v in pairs(prop) do
        _ocase[i] = v
    end
    return _ocase
end}

-- [[ CASE DEFS ]]
local Cases = {}
local Skins = require(script.Parent:WaitForChild("Skins"))

Cases.weaponcase1 = OCase.new({name = "Weapon Case 1"}):: OCase
Cases.weaponcase1.loot.common = {"vityaz_olReliable", "acr_jade"}
Cases.weaponcase1.loot.rare = {"hkp30_curvedPurple"}
Cases.weaponcase1.loot.epic = {"ak103_knight", "glock17_matteObsidian"}
Cases.weaponcase1.price_pc = 25
Cases.weaponcase1.price_sc = 250
Cases.weaponcase1.sell_sc = 187.5

-- [[ MODULE PRIVATE ]]
local CaseModule = {
    getCaseFromString = function(caseStr)
        return Cases[caseStr]
    end,
    getLootItemFromCase = function(case: OCase) -- Loot comes as "weapon_model_skin"
        local random = math.random(100, 10000)/100
        local rarity = getRarityFromNumber(random)
        local loot = case.loot[rarity][math.random(1, #case.loot[rarity])]
        local success, skin = pcall(function() return Skins.GetSkinFromString(loot) end)
        if success then
            skin = loot
        else
            skin = case.loot[rarity][1]
            warn("Skin from case does not exist. " .. tostring(loot) .. " - Did you make a def in 'Skins' ? " .. tostring(skin))
        end

        skin = Skins.ConvertShopSkinStrToInvStr(skin)
        return skin
    end
}

-- [[ MODULE PUBLIC ]]
return {
    OpenCase = function(caseStr)
        local case = CaseModule.getCaseFromString(caseStr)
        local playerSkin = CaseModule.getLootItemFromCase(case)

        local potentialSkins = {}
        for _ = 1, 10 do
            table.insert(potentialSkins, CaseModule.getLootItemFromCase(case))
        end

        return playerSkin, potentialSkins
    end,
    Cases = Cases
}
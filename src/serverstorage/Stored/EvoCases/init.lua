local Cases = {
    weaponcase1 = {
        loot = {
            common = {"vityaz_olReliable", "glock17_hexstripe", "ak103_hexstripe"},
            rare = {"glock17_curvedPurple", "hkp30_curvedPurple"},
            epic = {"ak103_knight", "glock17_matteObsidian"},
            legendary = {
                "knife_karambit_default", "knife_karambit_sapphire", "knife_karambit_ruby", "knife_karambit_matteObsidian",
                "knife_m9bayonet_default", "knife_m9bayonet_sapphire", "knife_m9bayonet_ruby", "knife_m9bayonet_matteObsidian"
            }
        }
    }
}

Cases.RarityInformation = {
    63,     -- common
    27,     -- rare
    8,      -- epic
    2       -- legendary
}

function GetRarityFromIndex(index)
    index = (index == 1 and "common") or (index == 2 and "rare") or (index == 3 and "epic") or (index == 4 and "legendary")
end

function GetRarityFromRandomNumber(number)
    local last = 0
    for index, value in pairs(Cases.RarityInformation) do
        if index == #Cases.RarityInformation or number == value or number <= last + value then
            return GetRarityFromIndex(index)
        end
        last += value
    end
end

function GetCaseLoot(case, random)
    random = random or Random.new()

    local rarity = GetRarityFromRandomNumber(random:NextInteger(1, 100))
    local lootIndex = random:NextInteger(1, #case.loot[rarity])
    return case.loot[rarity][lootIndex]
end

function Cases:Open(caseStr)
    local random = Random.new()
    local gotItem = GetCaseLoot(caseStr, random)

    local potentialItems = {}
    for _ = 1, 10 do
        table.insert(potentialItems, GetCaseLoot(Cases[caseStr], random))
    end

    return gotItem, potentialItems
end

return Cases
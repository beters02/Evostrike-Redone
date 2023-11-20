local http = game:GetService("HttpService")
local shared = require(script.Parent:WaitForChild("Shared"))
local function clone(t)
    local nt = {}
    for i, v in pairs(t) do
        nt[i] = v
    end
    return nt
end

-- [[ ALL OVERRIDES CONFIGURATION ]]
local Mods = {}

-- [ GROUP INVENTORIES ]
Mods.GroupInventoryAdd = {
    playtester = function(data)
        table.insert(data.ownedItems.skin, "knife_karambit_default_" .. http:GenerateGUID(false))
        table.insert(data.ownedItems.skin, "knife_karambit_sapphire_" .. http:GenerateGUID(false))
    end,
    admin = function(data)
        Mods.GroupInventoryAdd.playtester(data)
    end
}

-- [ INVENTORY MODIFICATIONS ]
Mods.GlobalInventoryModifications = {
    init = function(data)
        data.ownedItems = clone(shared.def.ownedItems)
    end,
    inventoryReset2 = function(data)
        Mods.GlobalInventoryModifications.init(data)
        for i, _ in pairs(data.states) do -- reset states
            if string.match(i, "invAdd_") then
                data.states[i] = false
            end
        end
    end
}

-- [[ MODULE ]]
return {
    InitPlayerInventory = function(data, group)
        local changed = false

        -- apply inventory modifications
        for i, func in pairs(Mods.GlobalInventoryModifications) do
            if not data.states["invMod_" .. i] then
                data.states["invMod_" .. i] = true
                func(data, group)
                changed = true
            end
        end

        -- apply group inventories
        if Mods.GroupInventoryAdd[group] then
            if not data.states["invAdd_" .. group] then
                data.states["invAdd_" .. group] = true
                Mods.GroupInventoryAdd[group](data)
                changed = true
            end
        end

        return changed
    end
}
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

local resets = require(script:WaitForChild("resets"))
local mods = require(script:WaitForChild("mods"))

--@summary Initialize Player's Inventory Modifications
local Invs = {}
Invs.Init = function(data, group)
    local changed = false
    changed = mods.ApplyMods(data)

    if group == "admin" then
        if not data.hasBeenGivenAdminInventoryA or not table.find(data.inventory.skin, "*") then
            print('has not admined')
            Invs.Give.admin(data)
            changed = true
        end
    elseif group == "playtester" then
        if not data.hasBeenGivenPlaytesterInventory then
            print('has not playtestered')
            Invs.Give.playtester(data, group)
            changed = true
        end
    end

    --[[local changedFromReset = resets.main(Invs, data, group) -- check for new reset states
    changed = changed or changedFromReset]]

    return changed
end

Invs.Give = {
    playtester = function(data, group)
        resets.new(data, group) -- since they are getting a fresh inventory, they have receieved all reset states
        data.hasBeenGivenPlaytesterInventory = true
        data.inventory.skin = {
            "knife_karambit_default",
            "knife_karambit_sapphire",
            "knife_m9bayonet_default"
        }
    end,

    admin = function(data)
        data.hasBeenGivenAdminInventoryA = true
        table.insert(data.inventory.skin, "*")
    end
}

return Invs
local DataStoreService = game:GetService("DataStoreService")
local resets = require(script:WaitForChild("inventoryResets"))

--@summary Initialize Player's Group & Event Inventory Modifications
local Invs = {}
Invs.Init = function(player, serverPlayerDataModule, group)
    if not group then return end
    local data = serverPlayerDataModule.GetPlayerData(player)
    if group == "admin" then
        if not data.hasBeenGivenAdminInventoryA or not table.find(data.inventory.skin, "*") then
            Invs.Give.admin(data, player, serverPlayerDataModule)
        end
    elseif group == "playtester" then
        if not data.hasBeenGivenPlaytesterInventory then
            Invs.Give.playtester(data, player, serverPlayerDataModule, group)
        else
            resets.main(Invs, player, serverPlayerDataModule, group) -- check for new reset states
        end
    end
end

Invs.Give = {
    playtester = function(data, player, serverPlayerDataModule, group)
        resets.new(player, serverPlayerDataModule, group) -- since they are getting a fresh inventory, they have receieved all reset states
        data.hasBeenGivenPlaytesterInventory = true
        data.inventory.skin = {
            "knife_karambit_default",
            "knife_karambit_sapphire",
            "knife_m9bayonet_default"
        }
        serverPlayerDataModule.SetPlayerData(player, data, true)
    end,

    admin = function(data, player, serverPlayerDataModule)
        data.hasBeenGivenAdminInventoryA = true
        table.insert(data.inventory.skin, "*")
        serverPlayerDataModule.SetPlayerData(player, data, true)
    end
}

return Invs
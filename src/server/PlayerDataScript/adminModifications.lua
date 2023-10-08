local DataStoreService = game:GetService("DataStoreService")
return function(player, serverPlayerDataModule, group)
    local data = serverPlayerDataModule.GetPlayerData(player)

    if not data.hasBeenGivenInventoryReset1 and group == "playtester" then
        data.inventory.skin = {
            "knife_karambit_*",
            "knife_m9bayonet_*"
        }
        data.hasBeenGivenPlaytesterInventory = true
        data.hasBeenGivenInventoryReset1 = true
        serverPlayerDataModule.SetPlayerData(player, data, true)
    end

    if group == "admin" then
        -- add all skins to admin inventory
        if not data.hasBeenGivenAdminInventoryA or not table.find(data.inventory.skin, "*") then
            data.hasBeenGivenAdminInventoryA = true
            table.insert(data.inventory.skin, "*")
            serverPlayerDataModule.SetPlayerData(player, data, true)
        end
    elseif group == "playtester" then
        
        -- add select skins to playtester inventory
        if not data.hasBeenGivenPlaytesterInventory then
            data.hasBeenGivenPlaytesterInventory = true
            table.insert(data.inventory.skin, "knife_karambit_*")
            table.insert(data.inventory.skin, "knife_m9bayonet_*")
            serverPlayerDataModule.SetPlayerData(player, data, true)
        end

    end
end
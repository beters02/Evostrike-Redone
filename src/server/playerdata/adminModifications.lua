return function(player, serverPlayerDataModule)
    local data = serverPlayerDataModule.GetPlayerData(player)
    if not data.hasBeenGivenAdminInventory then
        data.hasBeenGivenAdminInventory = true
        --[[table.insert(data.inventory.skin, "knife_karambit_default")
        table.insert(data.inventory.skin, "knife_karambit_sapphire")]]
        table.insert(data.inventory.skin, "knife_karambit_*")
        serverPlayerDataModule.SetPlayerData(player, data, true)
    end
end
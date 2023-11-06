--@summary Inventory Resets
--         When a playerdata key needs to be reset, this is where you would do it.

local resets = {}

--@summary Loop through new reset states, reset through invs if necessary
function resets.main(invs, player, serverPlayerDataModule, group)
    for i, func in pairs(resets) do
        if i == "main" then continue end
        local reset, data = func(player, serverPlayerDataModule, group)
        if reset then
            data[i] = true
            invs.Give[i](data, player, serverPlayerDataModule, group)
        end
    end
end

--@summary new inventory reset state data, sets all resets to true
function resets.new(player, serverPlayerDataModule, group)
    local data = serverPlayerDataModule.GetPlayerData(player)
    for i, v in pairs(resets.get()) do
        data[i] = true
    end
    serverPlayerDataModule.SetPlayerData(player, data, true)
end

--@summary get all reset keys
function resets.get()
    local strs = {}
    for i, _ in pairs(resets) do
        if i == "main" or i == "get" then continue end
        table.insert(strs, i)
    end
    return strs
end

--[[ inventory reset functions ]]

--@return to reset - bool
function resets.hasBeenGivenInventoryReset2(player, serverPlayerDataModule, group)
    local data = serverPlayerDataModule.GetPlayerData(player)
    if not data.hasBeenGivenInventoryReset2 then
        return true, data
    end
end

return resets
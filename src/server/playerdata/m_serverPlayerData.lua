local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local DataStore2 = require(Framework.sm_datastore2.Location)

local module = {}
module.defaultData = require(game:GetService("ServerScriptService"):WaitForChild("playerdata"):WaitForChild("defaultPlayerData"))

function module.GetPlayerData(player)
    local store = DataStore2("PlayerData", player)

    local profile

    local success, response = pcall(function()
        profile = store:Get(module.defaultData)
    end)

    if not success then
        print("Could not retrieve PlayerData, returning default")
        return module.defaultData
    end

    return profile
end

function module.SetPlayerData(player, newData)
    local store = DataStore2("PlayerData", player)

    local success, result = pcall(function()
        store:Set(newData)
    end)

    if not success then
        print("Could not set PlayerData")
        return false
    end

    return result
end

return module
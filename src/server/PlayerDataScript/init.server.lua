local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverPlayerDataModule = require(script:WaitForChild("m_serverPlayerData"))
local Remotes = ReplicatedStorage.PlayerData.remote
local Admins = require(game:GetService("ServerStorage"):WaitForChild("Stored"):WaitForChild("AdminIDs"))
--local inventoryOverrides = require(script:WaitForChild("inventoryOverrides"))

Remotes.sharedPlayerDataRF.OnServerInvoke = function(player, action, ...)
    if action == "Get" then
        return serverPlayerDataModule.GetPlayerData(player)
    elseif action == "Set" then
        return serverPlayerDataModule.SetPlayerData(player, ...)
    elseif action == "GetDefault" then
        local c = script.default:Clone()
        c.Parent = ReplicatedStorage.temp
        local c1 = script.defaultMinMax:Clone()
        c1.Parent = ReplicatedStorage.temp
        Debris:AddItem(c, 5)
        Debris:AddItem(c1, 5)
        return c, c1
    end
end

Players.PlayerAdded:Connect(function(player)
    --inventoryOverrides.Init(player, serverPlayerDataModule, Admins:IsHigherPermission(player))
end)

Players.PlayerRemoving:Connect(function(player)
    serverPlayerDataModule.SavePlayerData(player)
end)
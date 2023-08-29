local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverPlayerDataModule = require(script.Parent:WaitForChild("m_serverPlayerData"))
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("playerdata"):WaitForChild("remote")

Remotes.sharedPlayerDataRF.OnServerInvoke = function(player, action, ...)
    if action == "Get" then
        return serverPlayerDataModule.GetPlayerData(player)
    elseif action == "Set" then
        return serverPlayerDataModule.SetPlayerData(player, ...)
    elseif action == "GetDefault" then
        local c = script.Parent.defaultPlayerData:Clone()
        c.Parent = ReplicatedStorage.temp
        local c1 = script.Parent.defaultPlayerDataMinMax:Clone()
        c1.Parent = ReplicatedStorage.temp
        Debris:AddItem(c, 5)
        Debris:AddItem(c1, 5)
        return c, c1
    end
end

Players.PlayerRemoving:Connect(function(player)
    serverPlayerDataModule.SavePlayerData(player)
end)
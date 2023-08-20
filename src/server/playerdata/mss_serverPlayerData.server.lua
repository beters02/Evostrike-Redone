local Players = game:GetService("Players")

local serverPlayerDataModule = require(script.Parent:WaitForChild("m_serverPlayerData"))
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("playerdata"):WaitForChild("remote")

Remotes.sharedPlayerDataRF.OnServerInvoke = function(player, action, ...)
    if action == "Get" then
        return serverPlayerDataModule.GetPlayerData(player)
    elseif action == "Set" then
        return serverPlayerDataModule.SetPlayerData(player, ...)
    end
end

Players.PlayerRemoving:Connect(function(player)
    
end)
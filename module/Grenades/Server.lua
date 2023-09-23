local Players = game:GetService("Players")
local Remotes = script.Parent:WaitForChild("Remotes")

local Server = {}

Remotes.RemoteFunction.OnServerInvoke = function(player, action, ...)
    if action == "GetCaster" then
        local playerToGetCasterFrom = ...
        return Remotes.RemoteFunction:InvokeClient("GetCaster", playerToGetCasterFrom)
    end
    return false, warn("Cant find action " .. tostring(action))
end

Remotes.RemoteEvent.OnServerEvent = function(player, action, ...)
    if action == "CreateCaster" then
        Remotes.RemoteEvent:FireAllClients("CreateCaster", player)
    elseif action == "CreateCastBehavior" then
        Remotes.RemoteEvent:FireAllClients("CreateCastBehavior", player, ...)
    elseif action == "RemoveCaster" then
        Remotes.RemoteEvent:FireAllClients("RemoveCaster")
    end
end

Remotes.Replicate.OnServerEvent:Connect(function(player, action, ...)
    if action == "GrenadeFire" then
        local abilityName, origin, direction = ...
        for i, v in pairs(Players:GetPlayers()) do
            if v == player then continue end
            Remotes.Replicate:FireClient(v, action, abilityName, origin, direction)
        end
    end
end)

return Server
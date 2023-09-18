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
    end
end

return Server
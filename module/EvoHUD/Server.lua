local Server = {}

local RemoteEvent = script.Parent:WaitForChild("Events").RemoteEvent

function Server:EnablePlayerHUD(player: Player | "all")
    if player == "all" then
        RemoteEvent:FireAllClients("Enable")
    else
        RemoteEvent:FireClient(player, "Enable")
    end
    
end

function Server:DisablePlayerHUD(player: Player | "all")
    if player == "all" then
        RemoteEvent:FireAllClients("Disable")
    else
        RemoteEvent:FireClient(player, "Disable")
    end
end

return Server
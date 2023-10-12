local Client = {}
Client.player = game.Players.LocalPlayer

local RemoteEvent = script.Parent:WaitForChild("Events").RemoteEvent
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

function Client:AddLocal(ability)
    
end

function Client:AddGlobal(ability, owner)
    if owner == Client.player then
        return
    end

end

RemoteEvent.OnClientEvent:Connect(function(action, ...)
    assert(Client[action], "This action does not exist. " .. tostring(action))
    Client[action](Client, ...)
end)

return Client
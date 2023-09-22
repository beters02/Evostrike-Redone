local RunService = game:GetService("RunService")
if RunService:IsServer() then return end

local GMClient = {}
GMClient.__index = GMClient

GMClient.DefaultActionDelay = 0.5

GMClient.RemoteEvent = script.Parent:WaitForChild("RemoteEvent")
GMClient.RemoteFunction = script.Parent:WaitForChild("RemoteFunction")
GMClient.IsServiceInit = false
GMClient.Connections = {}

function _clientRemoteEvent(action)
    if action == "Init" then
        GMClient.IsServiceInit = true
    end
end

function GMClient:VerifyDebounce()
    if self._debounce and self._debounce > tick() then
        return false, "Wait a sec!"
    end
    self._debounce = tick() + GMClient.DefaultActionDelay
    return true
end

function GMClient:Connect()
    GMClient.IsServiceInit = GMClient.RemoteFunction:InvokeServer("IsInit")
    GMClient.Connections.RemoteEvent = GMClient.RemoteEvent.OnClientEvent:Connect(_clientRemoteEvent)
end

function GMClient:GetMenuType()
    return GMClient.RemoteFunction:InvokeServer("GetMenuType")
end

function GMClient:GetCurrentGamemode()
    local succ, err = self:VerifyDebounce()
    if not succ then return false, err end
    return GMClient.RemoteFunction:InvokeServer("GetCurrentGamemode")
end

function GMClient:ChangeGamemode(gamemode: string)
    local succ, err = self:VerifyDebounce()
    if not succ then return false, err end
    return GMClient.RemoteFunction:InvokeServer("ChangeGamemode", gamemode)
end

function GMClient:AttemptPlayerSpawn()
    local succ, err = self:VerifyDebounce()
    if not succ then return false, err end
    return GMClient.RemoteFunction:InvokeServer("AttemptPlayerSpawn")
end

return GMClient
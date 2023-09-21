local RunService = game:GetService("RunService")
if RunService:IsServer() then return end

local GMClient = {}
GMClient.__index = GMClient

GMClient.RemoteEvent = script.Parent:WaitForChild("RemoteEvent")
GMClient.RemoteFunction = script.Parent:WaitForChild("RemoteFunction")
GMClient.IsServiceInit = false
GMClient.Connections = {}

function _clientRemoteEvent(action)
    if action == "Init" then
        GMClient.IsServiceInit = true
    end
end

function GMClient:Connect()
    GMClient.IsServiceInit = GMClient.RemoteFunction:InvokeServer("IsInit")
    GMClient.Connections.RemoteEvent = GMClient.RemoteEvent.OnClientEvent:Connect(_clientRemoteEvent)
end

function GMClient:GetCurrentGamemode()
    return GMClient.RemoteFunction:InvokeServer("GetCurrentGamemode")
end

local debounce = tick()

function GMClient:ChangeGamemode(gamemode: string)
    if tick() < debounce then return false end
    return GMClient.RemoteFunction:InvokeServer("ChangeGamemode", gamemode)
end

return GMClient
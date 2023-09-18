local gamemode = require(script.Parent:WaitForChild("m_gamemode"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Gamemode = require(Framework.sm_gamemode.Location)
local SetRemote = ReplicatedStorage:WaitForChild("gamemode"):WaitForChild("remote"):WaitForChild("Set")
local GetRemote = ReplicatedStorage:WaitForChild("gamemode"):WaitForChild("remote"):WaitForChild("Get")
local ForceStartRemote = ReplicatedStorage:WaitForChild("gamemode"):WaitForChild("remote"):WaitForChild("ForceStart")

SetRemote.OnServerEvent:Connect(function(player, gamemodeName, permGroup)
    if permGroup and permGroup == "playtester" then
        if Gamemode.currentGamemode ~= "Range" and not Gamemode._wasChangedFromRange then
            return false
        end
        Gamemode._wasChangedFromRange = true
    end
    Gamemode.SetGamemode(gamemodeName)
end)

GetRemote.OnServerInvoke = function(player)
    task.wait()
    return Gamemode.currentGamemode
end

ForceStartRemote.OnServerEvent:Connect(function()
    Gamemode.currentClass:ForceStart()
    print('yuh')
end)

local nextUpdateTick = tick()
RunService.Heartbeat:Connect(function()
    if tick() >= nextUpdateTick then
        nextUpdateTick = tick() + 5
        MessagingService:PublishAsync("ServerInfo", {PlaceID = game.PlaceId, JobID = game.JobId, Gamemode = tostring(Gamemode.currentGamemode)})
    end
end)

gamemode.Init()
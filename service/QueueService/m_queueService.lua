--[[
    To Do:

    Connect MessagingService:SubscribeAsync("RemovePlayer"), "RemovePlayerResult", "GetPlayerData", "GetPlayerDataResult"
]]

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local TeleportService = game:GetService("TeleportService")
local PlayerData = require(Framework.sm_serverPlayerData.Location)
local SharedRequestRemote = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("requestQueueFunction")

local QueueService = {}
QueueService.__index = QueueService
QueueService.__location = game:GetService("ReplicatedStorage").Services.QueueService
QueueService.__status = "dead"

--

function QueueService:Start()

    -- init manager
    QueueService.Manager = require(self.__location.QueueManager)
    QueueService.Manager:StartManager(QueueService)

    -- init remote
    QueueService.__remote = function(...)
        require(self.__location.Remote)(self, ...)
    end

    -- connect
    QueueService:Connect()

    -- set running
    QueueService.__status = "running"
    print('Queue Service Started!')
end

function QueueService:Stop()
    QueueService.Manager:StopManager()
    QueueService:Disconnect()
    QueueService.__status = "dead"
    print('Queue Service Stopped!')
end

--

function QueueService:Connect()

    -- connect Remote
    SharedRequestRemote.OnServerInvoke = QueueService.__remote

    local conn = {}
    conn.RemovePlayer = MessagingService:SubscribeAsync("RemovePlayer", function(playerName, queueName)
        if not Players:FindFirstChild(playerName) then return end
        local result, error = QueueService.Manager.Queues[queueName]:RemovePlayer(Players[playerName])
        MessagingService:PublishAsync("RemovePlayerResult", {Name = playerName, Result = result, Error = error})
    end)

    conn.GetPlayerData = MessagingService:SubscribeAsync("GetPlayerData", function(playerName)
        if not Players:FindFirstChild(playerName) then return end
        local playerData = PlayerData:GetPlayerData(Players[playerName])
        MessagingService:PublishAsync("GetPlayerDataResult", {Name = playerName, Result = playerData})
    end)

    conn.TeleportPlayer = MessagingService:SubscribeAsync("TeleportPlayer", function(playerName, action, prop)
        if not Players:FindFirstChild(playerName) then return end
        if action == "private" then
            TeleportService:TeleportToPrivateServer(prop.PlaceID, prop.PrivateCode, {Players[playerName]}, false, {RequestedGamemode = prop.Gamemode})
        elseif action == "public" then
            TeleportService:TeleportAsync(prop.PlaceID, {Players[playerName]}, prop.TeleportOptions)
        end
    end)

    QueueService._connections = conn
end

function QueueService:Disconnect()
    for i, v in pairs(QueueService._connections) do
        v:Disconnect()
    end
    QueueService._connections = {}
end

--

function QueueService:IsRunning()
    return QueueService.__status == "running"
end

return QueueService
--[[
    To Do:

    Connect MessagingService:SubscribeAsync("RemovePlayer"), "RemovePlayerResult", "GetPlayerData", "GetPlayerDataResult"
]]

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SharedRequestRemote = game:GetService("ReplicatedStorage"):WaitForChild("Services").QueueService.Remote.shared.requestQueueFunction

local QueueService = {}

-- Client indexing
if RunService:IsClient() then
    QueueService.IsInQueue = function(player)
    end
    return QueueService
end

QueueService.__index = QueueService
QueueService.__location = game:GetService("ReplicatedStorage").Services.QueueService
QueueService.__status = "dead"
QueueService.__localPlayerData = require(QueueService.__location.ServicePlayerData)
QueueService.__types = require(QueueService.__location.Types)

local Remote = require(QueueService.__location.Remote)
local Types = QueueService.__types
QueueService.Manager = require(QueueService.__location.Manager)

--

-- Easy access add player/remove player
function QueueService:AddPlayer(queueName, playerName)
    return self.Manager.Queues[queueName].playerManager:Add(playerName)
end

function QueueService:RemovePlayer(queueName, playerName)
    return self.Manager.Queues[queueName].playerManager:Remove(playerName)
end

--

function QueueService:Start()

    print('Starting manager!')

    -- init manager
    QueueService.Manager:StartManager(QueueService)

    print('Starting remote!')

    -- init remote function grab
    QueueService.__remote = function(...)
        return Remote(QueueService, ...)
    end

    print('Starting service!')

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

function QueueService:Connect()
    local conn = {}

    -- connect Remote
    SharedRequestRemote.OnServerInvoke = QueueService.__remote

    -- connect LocalPlayerData
    conn.playerAdded = Players.PlayerAdded:Connect(function(player)
        QueueService.__localPlayerData[player.Name] = {Name = player.Name, Processing = false, InQueue = false} :: Types.QueueServicePlayerData
    end)

    -- remove LocalPlayerData
    conn.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        if QueueService.__localPlayerData[player.Name] then

            -- todo: update var if necessary
            QueueService.__localPlayerData[player.Name] = nil
        end
    end)

    -- connect MessagingService
    conn = _connectMessagingService(conn)

    -- init _connections
    QueueService._connections = conn
end

function QueueService:Disconnect()
    if not QueueService._connections then return end
    for i, v in pairs(QueueService._connections) do
        v:Disconnect()
    end
    QueueService._connections = {}
end

--

function QueueService:IsRunning()
    return QueueService.__status == "running"
end

--

function _connectMessagingService(conn)
    
    -- Grab Local Queue PlayerData (Processing)
    conn.messagingGetLocalQueuePlayerData = MessagingService:SubscribeAsync("GetLocalQueuePlayerData", function(playerName)
        if not Players:FindFirstChild(playerName) then return end
        return QueueService.__localPlayerData[playerName]
    end)

    --[[conn.RemovePlayer = MessagingService:SubscribeAsync("RemovePlayer", function(playerName, queueName)
        if not Players:FindFirstChild(playerName) then return end
        local result, error = QueueService.Manager.Queues[queueName]:RemovePlayer(Players[playerName])
        MessagingService:PublishAsync("RemovePlayerResult", {Name = playerName, Result = result, Error = error})
    end)]]

    --[[conn.GetPlayerData = MessagingService:SubscribeAsync("GetPlayerData", function(playerName)
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
    end)]]

    return conn
end

return QueueService
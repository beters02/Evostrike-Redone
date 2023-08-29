--[[
    To Do:

    Connect MessagingService:SubscribeAsync("RemovePlayer"), "RemovePlayerResult", "GetPlayerData", "GetPlayerDataResult"
]]

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local TeleportService = game:GetService("TeleportService")
local PlayerData = require(Framework.sm_serverPlayerData.Location)
local Gamemode = require(Framework.sm_gamemode.Location)
local SharedRequestRemote = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("requestQueueFunction")
local StoredMapIDs = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))

local QueueService = {}
QueueService.__index = QueueService
QueueService.__location = game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("QueueService")

function QueueService:Start()
    QueueService.Manager = require(self.__location.QueueManager)
    QueueService.Manager:StartManager(QueueService)
    QueueService:Connect()
    print('Started!')
end

function QueueService:Stop()
end

--

function QueueService:Connect()
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

    conn.GetServerInfo = MessagingService:SubscribeAsync("GetServerInfo", function()
        MessagingService:PublishAsync("GetServerInfoResult", {placeid = game.PlaceId, jobid = game.JobId, gamemode = Gamemode.currentGamemode, totalPlayers = Gamemode.GetTotalPlayerCount()})
    end)

    SharedRequestRemote.OnServerInvoke = requestQueueFunc

    QueueService._connections = conn

end

function requestQueueFunc(player: Player, action: string, ...)
    if action == "Add" then
        if not QueueService.Manager.Queues[...] then return false end
        return QueueService.Manager.Queues[...]:AddPlayer(player)
    elseif action == "Remove" then
        if not QueueService.Manager.Queues[...] then return false end
        return QueueService.Manager.Queues[...]:RemovePlayer(player)
    elseif action == "ClearAll" then
        --[[for i, v in pairs(queueService) do
            if type(v) ~= "table" then continue end
            if v.isQueueClass then
                v:ClearAllPlayers()
            end
        end]]
    elseif action == "PrintAll" then
        --[[for i, v in pairs(queueService) do
            if type(v) ~= "table" then continue end
            if v.isQueueClass then
                v:PrintAllPlayers()
            end
        end]]
    elseif action == "TeleportPrivateSolo" then
        TeleportService:TeleportToPrivateServer(14504041658, TeleportService:ReserveServer(14504041658), {player}, false, {RequestedGamemode = "Range"})
        return true
    elseif action == "MapCommand" then
        local mapName, players = ...

        if not StoredMapIDs[string.lower(mapName)] then
            return false, "Couldn't find map"
        end

        local _priv = TeleportService:ReserveServer(StoredMapIDs[string.lower(mapName)])
        if not players then players = {player} end

        TeleportService:TeleportToPrivateServer(StoredMapIDs[string.lower(mapName)], _priv, players, false, "Range")

        return true
    end
end

return QueueService
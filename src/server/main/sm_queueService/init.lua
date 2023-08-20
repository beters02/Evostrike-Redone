--[[
    Automatically initialized when required for the first time
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local queueServiceLocation = game:GetService("ServerScriptService"):WaitForChild("main").sm_queueService
local sharedRequestRemote = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("requestQueueFunction")

local queueService = {
    serviceStatus = "running",
    connections = {},
    playerdata = {}
}
queueService.__index = queueService

function queueService:StartService()
    -- grab all datastore classes
    queueService._classmodules = {}
    for i, v in pairs(queueServiceLocation.class:GetChildren()) do
        if not v:IsA("ModuleScript") then continue end

        queueService._classmodules[i] = v

        -- init all classes
        queueService[v.Name] = require(queueServiceLocation.class).new(v.Name, queueService)
    end

    -- connect
    queueService:ConnectService()

    queueService.serviceStatus = "running"
    return queueService
end

function queueService:StopService()
    -- disconnect all running queues
    for i, v in pairs(queueService) do
        if not v.Disconnect then continue end
        v:Disconnect()
    end

    -- disconnect service connections
    queueService:DisconnectService()

    queueService.serviceStatus = "dead"
end

--

function queueService:ConnectService()
    sharedRequestRemote.OnServerInvoke = requestQueueFunc

    queueService.connections.playerAdded = Players.PlayerAdded:Connect(function(player)
        queueService:playerAdded(player)
    end)

    -- init any already existing players
    for i, v in pairs(Players:GetPlayers()) do
        queueService:playerAdded(v)
    end

    queueService.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
        queueService:playerRemoving(player)
    end)
end

function queueService:DisconnectService()
    sharedRequestRemote.OnServerInvoke = function() error("QueueService is dead!") end
    for i, v in pairs(queueService.connections) do v:Disconnect() queueService.connections[i] = nil end
end

--

function queueService:AddPlayer(player: Player, queue: string)
    if not queueService[queue] then warn("Could not add player to queue, can't find Queue [queueName]: " .. queue) return false end
    local success = queueService[queue]:RequestPlayerAdd(player)

    if success then
        queueService.playerdata[player.Name].CurrentQueue = queue
    end

    return success
end

function queueService:RemovePlayer(player: Player, queue: string)
    if not queueService[queue] then warn("Could not remove player from queue, can't find Queue [queueName]: " .. queue) return false end
    local success = queueService[queue]:RequestPlayerRemove(player)

    if success then
        queueService.playerdata[player.Name].CurrentQueue = false
    end

    return success
end

--

function requestQueueFunc(player: Player, action: string, queueName: string)
    if action == "Add" then
        return queueService:AddPlayer(player, queueName)
    elseif action == "Remove" then
        return queueService:RemovePlayer(player, queueName)
    end
end

function queueService:playerAdded(player: Player)
    queueService.playerdata[player.Name] = {CurrentQueue = false}
end

function queueService:playerRemoving(player: Player)
    if queueService.playerdata[player.Name] then
        if queueService.playerdata[player.Name].CurrentQueue then
            queueService:RemovePlayer(player, queueService.playerdata[player.Name].CurrentQueue)
        end
        queueService.playerdata[player.Name] = nil
    end
end

return queueService:StartService()
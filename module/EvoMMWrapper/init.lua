local MatchmakingService
local RunService = game:GetService("RunService")
local Bridge = script:WaitForChild("Bridge")
local RemoteEvent = script:WaitForChild("Remote")
local StoredMapIDs
local GameFoundGui = script:WaitForChild("GameFoundGui")

local module = {}

module.Bridge = Bridge
module.Remote = RemoteEvent
module.Running = false

function module:StartQueueService(queueableGamemodes)
    if RunService:IsClient() then return end

    -- custom tele data
    MatchmakingService.ApplyCustomTeleportData = function(_, gameData)
        return {RequestedGamemode = string.split(gameData.map, "_")[2]}
    end

    -- game found
    MatchmakingService.FoundGame:Connect(function(player)
        GameFoundGui:Clone().Parent = player
    end)

    -- init gamemodes
    for _, gamemode in pairs(queueableGamemodes) do
        --[[local req = game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("GamemodeService2").GamemodeScripts:FindFirstChild(gamemode)
        if not req then continue end
        req = require(req)

        -- init gamemode's maps
        for map, mapid in pairs(StoredMapIDs.GetMapInfoInGamemode(gamemode)) do
            MatchmakingService:SetPlayerRange(map .. "_" .. gamemode, NumberRange.new(req.minimumPlayers or 1, req.maximumPlayers or 8))
            MatchmakingService:AddGamePlace(map .. "_" .. gamemode, mapid)
        end]]
    end

    -- update queue count
    self._Stop = false
    self._UpdateQueueCount = task.spawn(function()
        while not self._Stop do
            task.wait(2)
            self:PushGamemodeQueueCount("Deathmatch")
            self:PushGamemodeQueueCount("1v1")
        end
    end)

    module.Running = true

    print('MatchmakingService Started!')
end

function module:StopQueueService()
    if not module.Running then return end
    module.Running = false
    self._Stop = true
    MatchmakingService.FoundGame:Disconnect()
    coroutine.yield(self._UpdateQueueCount)
end

function module:AddPlayerToQueue(player, queue)
    if RunService:IsClient() then
        local res = Bridge:InvokeServer("AddPlayerToQueue", queue)
        return res
    end

    local succ, err = pcall(function()
        for map, _ in pairs(StoredMapIDs.GetMapInfoInGamemode(queue)) do
            MatchmakingService:QueuePlayer(player, "main", map .. "_" .. queue)
        end
    end)

    if err then warn(tostring(err)) end

    return succ
end

function module:RemovePlayerFromQueue(player)
    if RunService:IsClient() then
        return Bridge:InvokeServer("RemovePlayerFromQueue", player)
    end
    return MatchmakingService:RemovePlayerFromQueue(player)
end


function module:GetGamemodeQueueCount(gamemode)
    if RunService:IsClient() then
        return Bridge:InvokeServer("GetGamemodeQueueCount", gamemode)
    end

    local counts = MatchmakingService:GetQueueCounts()
    if not counts or type(counts) ~= "table" then return 0 end

    local count = 0
    for map, info in pairs(counts) do -- Each gamemode has multiple queues with maps for the gamemode.
        if not info then continue end -- We will only need to count one of the maps since players queue for all maps when queueing for gamemode.
        if not string.match(map, gamemode) then
            continue
        end

        for _, tab in pairs(info) do -- Queue has multiple categories
            for _, cnt in pairs(tab) do -- Categories have player categories
                count += cnt
            end
        end

        return count -- Counted once, now we return.
    end
end

function module:PushGamemodeQueueCount(gamemode)
    if RunService:IsClient() then return end
    RemoteEvent:FireAllClients("SetGamemodeQueueCount", gamemode, self:GetGamemodeQueueCount(gamemode))
end

if RunService:IsServer() then
    MatchmakingService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("MatchmakingService")).GetSingleton()
    module.MatchmakingService = MatchmakingService
    StoredMapIDs = require(game:GetService("ServerStorage"):WaitForChild("Stored"):WaitForChild("MapIDs"))
    Bridge.OnServerInvoke = function(player, action, queue)
        return module[action](module, player, queue)
    end
end

return module
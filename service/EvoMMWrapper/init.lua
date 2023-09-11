local MatchmakingService
local RunService = game:GetService("RunService")
local Bridge = script:WaitForChild("Bridge")
local StoredMapIDs

local module = {}

function module:StartQueueService(gamemodes)
    if RunService:IsClient() then return end
    for _, gamemode in pairs(gamemodes) do
        local req = require(game:GetService("ServerScriptService"):WaitForChild("gamemode").class[gamemode])
        -- init maps
        for map, mapid in pairs(StoredMapIDs.GetMapInfoInGamemode(gamemode)) do
            MatchmakingService:SetPlayerRange(map .. "_" .. gamemode, NumberRange.new(req.minimumPlayers or 1, req.maximumPlayers or 8))
            MatchmakingService:AddGamePlace(map .. "_" .. gamemode, mapid)
            print('init ' .. map .. "_" .. gamemode)
        end
    end
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

if RunService:IsServer() then
    MatchmakingService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("MatchmakingService")).GetSingleton()
    StoredMapIDs = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))
    Bridge.OnServerInvoke = function(player, action, queue)
        return module[action](module, player, queue)
    end
end

return module
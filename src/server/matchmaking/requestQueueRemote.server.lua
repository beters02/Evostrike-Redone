local TeleportService = game:GetService("TeleportService")
local StoredMapIDs = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))
local Gamemode = require(game:GetService("ServerScriptService"):WaitForChild("gamemode"):WaitForChild("m_gamemode"))
local EvoMM = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("EvoMMWrapper"))

local remote = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("requestQueueFunction")

local requestActions = {
    Add = function(player, ...)
        if not Gamemode.currentGamemode == "Lobby" then return end
        return EvoMM:AddPlayerToQueue(player, ...)
    end,
    Remove = function(player, ...)
        if not Gamemode.currentGamemode == "Lobby" then return end
        return EvoMM:RemovePlayerFromQueue(player)
    end,
    PrintAll = function()
    end,
    ClearAll = function()
    end,

    TeleportPrivateSolo = function(player, map) -- todo: get mapid. for now its warehouse
        map = map and StoredMapIDs.mapIds[string.lower(map)].id or 14504041658
        TeleportService:TeleportToPrivateServer(map, TeleportService:ReserveServer(StoredMapIDs.mapIds.warehouse.id), {player}, false, {RequestedGamemode = "Range"})
        return true
    end,
    
    TeleportPublicSolo = function(player, map)
        TeleportService:Teleport(StoredMapIDs.mapIds[string.lower(map)].id, player)
        return true
    end,
}

remote.OnServerInvoke = function(player, action, ...)
    return requestActions[action] and requestActions[action](player, ...)
end
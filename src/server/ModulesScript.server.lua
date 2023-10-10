local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Framework = require(ReplicatedStorage.Framework)

--EvoConsole
require(Framework.Module.EvoConsole)

--EvoMM
local EvoMM = require(Framework.Module.EvoMMWrapper)
local GamemodeService = require(Framework.Service.GamemodeService)
local StoredMapIDs = require(ServerStorage:WaitForChild("Stored"):WaitForChild("MapIDs"))
local queueRemote = Framework.Module.shared.Remotes.requestQueueFunction
local requestActions = {
    Add = function(player, ...)
        if GamemodeService.Gamemode.Name ~= "Lobby" then return end
        return EvoMM:AddPlayerToQueue(player, ...)
    end,
    Remove = function(player, ...)
        if GamemodeService.Gamemode.Name ~= "Lobby" then return end
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

queueRemote.OnServerInvoke = function(player, action, ...)
    return requestActions[action] and requestActions[action](player, ...)
end
--

--States
local statesloc = Framework.Module.m_states
local states = require(statesloc)
local statesMainRF: RemoteFunction = statesloc.remote.RemoteFunction
function init_connections()
    statesMainRF.OnServerInvoke = remote_main
end

function remote_getStateVar(stateName: string, key: string)
    return states[stateName].var[key]
end

function remote_setStateVar(stateName: string, key: string, value: any)
    -- add some verification eventually
    states[stateName].var[key] = value
    return states[stateName].var[key]
end

function remote_main(player, action, ...)
    if action == "getVar" then
        return remote_getStateVar(...)
    elseif action == "setVar" then
        return remote_setStateVar(...)
    end
end
--

--Sound
local replicateSoundRemote = Framework.Module.Sound:WaitForChild("remote").replicate
replicateSoundRemote.OnServerEvent:Connect(function(player, action, sound, whereFrom, volume)
    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v == player then continue end
        replicateSoundRemote:FireClient(v, action, sound, whereFrom)
    end
end)
--

--PlayerData
require(Framework.Module.PlayerData)

--EvoEconomy
local EvoEconomy = require(Framework.Module.EvoEconomy)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.delay(5, function()
            EvoEconomy:Increment(player, "StrafeCoins", 1)
        end)
    end)
end)

--Shop
require(Framework.Module.EvoShop)
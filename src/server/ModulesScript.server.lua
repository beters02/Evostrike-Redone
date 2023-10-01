local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StoredMapIDs = require(game:GetService("ServerStorage"):WaitForChild("Stored"):WaitForChild("MapIDs"))
local EvoMM = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EvoMMWrapper"))
local GamemodeService = require(ReplicatedStorage:WaitForChild("Services"):WaitForChild("GamemodeService"))
local Framework = require(ReplicatedStorage.Framework)
local statesloc = ReplicatedStorage:WaitForChild("states")
local states = Framework.shm_states or Framework.__index(Framework, "shm_states")
local statesMainRF: RemoteFunction = statesloc:WaitForChild("remote").mainrf
local queueRemote = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("requestQueueFunction")
local replicateSoundRemote = game:GetService("ReplicatedStorage"):WaitForChild("sound"):WaitForChild("remote"):WaitForChild("replicate")

--EvoConsole
require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EvoConsole"))

--EvoMM
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
replicateSoundRemote.OnServerEvent:Connect(function(player, action, sound, whereFrom, volume)
    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v == player then continue end
        replicateSoundRemote:FireClient(v, action, sound, whereFrom)
    end
end)
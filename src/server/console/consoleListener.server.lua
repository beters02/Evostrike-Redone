local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local StoredMapIDs = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))
local Admins = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedAdminNames"))

local _remotes = game:GetService("ReplicatedStorage"):WaitForChild("console"):WaitForChild("remotes")
local _function = _remotes:WaitForChild("CommandFunction")
--local _event = _remotes:WaitForChild("CommandEvent")

local _storedModules = {}

-- Player Command Initialization

function _initCommandsModule(player)

    _storedModules[player.Name] = {general = script.Parent.Commands.general:Clone()}
    _storedModules[player.Name].general.Parent = ReplicatedStorage.temp

    -- add admin commands if player is admin
    if Admins:IsAdmin(player) then
        _storedModules[player.Name].admin = script.Parent.Commands.admin:Clone()
        _storedModules[player.Name].admin.Parent = ReplicatedStorage.temp
    end
    
    return _storedModules[player.Name]
end

function _playerRemovingDestroyCommandsModule(player)
    if _storedModules[player.Name] then
        for _, a in pairs(_storedModules[player.Name]) do
            for i, v in pairs(a) do
                v:Destroy()
            end
        end
        _storedModules[player.Name] = nil
    end
end

Players.PlayerRemoving:Connect(_playerRemovingDestroyCommandsModule)

-- Remote Function Initialization

local _functionActions = {

    InitCommandsModule = _initCommandsModule,

    TeleportPrivateSolo = function(player) -- todo: get mapid. for now its warehouse
        TeleportService:TeleportToPrivateServer(14504041658, TeleportService:ReserveServer(StoredMapIDs.warehouse.id), {player}, false, {RequestedGamemode = "Range"})
        return true
    end,

    MapCommand = function(player, ...)
        local mapName, players = ...

        if not StoredMapIDs[string.lower(mapName)] then
            return false, "Couldn't find map"
        end
    
        local _priv = TeleportService:ReserveServer(StoredMapIDs[string.lower(mapName).id])
        if not players then players = {player} end
    
        TeleportService:TeleportToPrivateServer(StoredMapIDs[string.lower(mapName).id], _priv, players, false, "Range")
        return true
    end
}

local function onCommandRemoteFunction(player, action, ...)
    if not _functionActions[action] then
        warn("server.main.consoleListener: Cannot find functionAction" .. tostring(action))
        return false, "server.main.consoleListener: Cannot find functionAction" .. tostring(action)
    end

    return _functionActions[action](player, ...)
end

_function.OnServerInvoke = onCommandRemoteFunction
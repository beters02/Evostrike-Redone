--[[
    Initialized on Require, must be initialized on Client and Server
]]
local RunService = game:GetService("RunService")
if RunService:IsClient() then
    return require(script:WaitForChild("Client"))
end

local DataStore2 = require(script:WaitForChild("DataStore2"))
local Strings = require(script:WaitForChild("Strings"))
local Shared = require(script:WaitForChild("Shared"))
local RemoteFunction = script:WaitForChild("Events").RemoteFunction
local RemoteEvent = script.Events.RemoteEvent
local Admins = require(game:GetService("ServerStorage"):WaitForChild("Stored").AdminIDs)
local Overrides = require(script:WaitForChild("Overrides"))

local PlayerData = {}
PlayerData._storecache = {}
PlayerData._def, PlayerData._defOpt = Shared.def, Shared.defVar

--@summary Get PlayerData
function PlayerData:Get(player: Player)
    return _compareToDefault(player, _getDataSafe(player, true))
end

--@summary Get PlayerData without checking for missing keys
function PlayerData:GetAsync(player: Player)
    return _getDataSafe(player)
end

--@summary Get the value of a PlayerDataKey (will return table)
function PlayerData:GetKey(player, key)
    return PlayerData:GetAsync(player)[key]
end

--@summary Get the value of a key from a PlayerDataKey table
function PlayerData:GetPath(player, path) -- path: options.primaryFire
    return Strings.convertPathToInstance(path, PlayerData:GetAsync(player))
end

--@summary Set the PlayerData to a new PlayerData
type Key = string
type Path = string
export type dataChangedInfo = {location: "Set" | "Key" | "Path", key: Key | Path | nil, new: any?}
function PlayerData:Set(player, new, changed: dataChangedInfo?, save, ignoreRemote)
    if not changed then changed = {location = "Set"} end
    local store = _getStoreSafe(player)
    store:Set(new)
    if save then
        store:Save()
    end
    if not ignoreRemote then
        RemoteEvent:FireClient(player, "SetAsync", new, changed)
    end
    return new
end

--@summary Set a specific key of the PlayerData
function PlayerData:SetKey(player, key, new)
    local playerdata = PlayerData:GetAsync(player)
    playerdata[key] = new
    return PlayerData:Set(player, playerdata, {location = "Key", key = key, new = new})
end

--@summary Set the value of a key from the PlayerData path
function PlayerData:SetPath(player, path, new)
    local playerdata = PlayerData:GetAsync(player)
    Strings.doActionViaPath(path, playerdata, function(gotTableParent, key)
        gotTableParent[key] = new
    end)
    return PlayerData:Set(player, playerdata, {location = "Path", key = path, new = new})
end

--@summary Increment the value of a key from the PlayerData path
function PlayerData:IncrementPath(player, path, amnt)
    local playerdata = PlayerData:GetAsync(player)
    local new
    Strings.doActionViaPath(path, playerdata, function(gotTableParent, key)
        new = gotTableParent[key] + amnt
        gotTableParent[key] = new
    end)
    return PlayerData:Set(player, playerdata, {location = "Path", key = path, new = new})
end

--@summary Decrement the value of a key from the PlayerData path
function PlayerData:DecrementPath(player, path, amnt)
    local playerdata = PlayerData:GetAsync(player)
    local new
    Strings.doActionViaPath(path, playerdata, function(gotTableParent, key)
        new = gotTableParent[key] - amnt
        gotTableParent[key] = new
    end)
    return PlayerData:Set(player, playerdata, {location = "Path", key = path, new = new})
end

--@summary Insert a value into a table via path
function PlayerData:TableInsert(player, path, object)
    local playerdata = PlayerData:GetAsync(player)
    local new
    Strings.doActionViaPath(path, playerdata, function(gotTableParent, key)
        table.insert(gotTableParent[key], object)
        new = gotTableParent[key]
    end)
    task.spawn(function()
        local event = player:WaitForChild("PlayerDataChanged", 3)
        if event then
            event:FireClient(player, "Path", new, path)
        end
    end)
    return PlayerData:Set(player, playerdata, {location = "Path", key = path, new = new})
end

--@summary Save the PlayerData
function PlayerData:Save(player)
    _getStoreSafe(player):Save()
end

function PlayerData:SaveWithRetry(player, sec, isAssert)
    local succ, _ = pcall(function()
        PlayerData:Save(player)
    end)
    if succ then return end
    local _et = tick() + sec
    while not succ and tick() < _et do
        succ, _ = pcall(function()
            PlayerData:Save(player)
        end)
    end
    if not succ and isAssert then
        error("Could not save " .. player.Name .. "'s PlayerData!")
    end
end

function PlayerData:ClearPlayerCache(player)
    PlayerData._storecache[player.Name] = nil
end

--@summary Set an Option Value, enforcing limits and type restrictions.
function PlayerData:SetOptionValue(player, optionKey, valueKey, value)
    if not Shared:VerifyNewOptionValue(optionKey, valueKey, value) then
        return false, "Option value not verified."
    end
    return PlayerData:SetPath(player, "options." .. optionKey .. "." .. valueKey, value)
end

--@private
--[[Private Module Functions]]
function _serverInvoke(player, action, ...)
    if action == "Get" then
        return PlayerData:Get(player)
    elseif action == "Set" then
        return _clientRequestToSet(player, ...)
    end
end

function _serverPlayerAdded(player)
    PlayerData:Get(player)
end

function _serverPlayerRemoving(player)
    task.delay(3, function()
        PlayerData:ClearPlayerCache(player)
    end)
end

function _getStoreSafe(player)
    local store = PlayerData._storecache[player.Name]
    if not store then
        store = DataStore2("PlayerData", player)
        assert(store, "Could not get DataStore")
        PlayerData._storecache[player.Name] = store
    end
    return store
end

function _getDataSafe(player, getTable)
    local store = _getStoreSafe(player)
    local data = (getTable and store.GetTable or store.Get)(store, PlayerData._def)
    assert(data, "Could not get playerdata. PlayerDataSetKey")
    return data
end

function _hardCopy(variant: any)
    local copy
    if type(variant) ~= "table" then
        copy = variant
    else
        copy = {}
        for i,v in pairs(variant) do
            copy[i]=v
        end
    end
    return copy
end

--@summary Overrides unvalidated data with what was previously stored.
function _validateIncoming(player, new)
    local _rep = false
    for i, v in pairs(new) do
        if PlayerData._defOpt[i] and PlayerData._defOpt[i].clientReadOnly then
            _rep = PlayerData:GetKey(player, i)
            
            for a, b in pairs(v) do
                if _rep[a] ~= b then
                    new[i] = _hardCopy(_rep)
                    warn("Could not validate playerdata key '" .. tostring(i) .. "' ... overriding with default value.")
                    break
                end
            end
        end
    end
end

function _clientRequestToSet(player, new)
    _validateIncoming(player, new)
    return PlayerData:Set(player, new, false, true)
end

--@private
--[[Default Player Data]]
function _compareToDefault(player, playerData)
    local changed = _compareRecurse(playerData, PlayerData._def)
    local _, group = Admins:IsHigherPermission(player)
    local invChanged = Overrides.InitPlayerInventory(playerData, group)
    changed = changed or invChanged
    if changed then
        PlayerData:Set(player, playerData)
        PlayerData:Save(player)
    end
    return playerData, changed
end

function _compareRecurse(start, defloc)
    local changed = false
    for i, v in pairs(defloc) do
        if start[i] == nil then
            start[i] = v
            changed = true
        end
        if type(v) == "table" then
            local _c = _compareRecurse(start[i], defloc[i])
            changed = changed or _c
        end
    end
    return changed
end

--@run
--[[Script Start]]
RemoteFunction.OnServerInvoke = _serverInvoke

return PlayerData
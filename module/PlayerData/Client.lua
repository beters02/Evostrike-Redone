--[[
    ClientPlayerData "Singleton" Module
    Initialize once in StarterPlayerScripts

    Contains a Client Cache of PlayerData which can be pushed to the server by calling Client:Save()

    ClientReadOnly values cannot be edited here.
    The server will run checks to be sure that the ClientReadOnly values will not be edited.

    Save()
        -- There isnt much need to call Save() since changes will be automatically saved to the server.
        -- Saving does NOT push the Data to DataStores.
        -- The data will be sent in a RemoteFunction to DataStores when the Client leaves.
]]

-- CONFIG
local clientWaitSec = 3
local changedUpdateSec = 3 -- amount of time waited for new change before saving
--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
if RunService:IsServer() then return end

local Strings = require(script.Parent:WaitForChild("Strings"))
local Shared = require(script.Parent:WaitForChild("Shared"))
local Events = script.Parent:WaitForChild("Events")
local RemoteFunction = Events:WaitForChild("RemoteFunction")
local RemoteEvent = Events:WaitForChild("RemoteEvent")
local player = Players.LocalPlayer
local conn = {}

export type Client = {
    Get: (self: Client) -> (Shared.PlayerData),
    GetKey: (self: Client, key: string) -> (any),
    GetPath: (self: Client, key: string) -> (any)
}

local Client = {_cache = false, _changed = false, _listeners = {}, _changedEvent = Instance.new("BindableEvent", script)}
Client._def, Client._defvar = Shared.def, Shared.defVar

function Client:Get(): Shared.PlayerData | false
    return _waitForCache()
end

function Client:UpdateFromServer()
    return _getFromServer(true)
end

function Client:GetKey(key)
    return Client._cache[key]
end

function Client:GetPath(path)
    return Strings.convertPathToInstance(path, Client._cache)
end

function Client:Set(new)
    Client:Get()
    Client._cache = new
    Client._changed = tick() + changedUpdateSec
    _fireChanged("PlayerData", new)
    return new
end

--@summary Change without changing on the server. Will still fire Changed.
function Client:SetAsync(new, changed)
    local location = "PlayerData"
    local key = nil
    local cnew = new
    if changed then
        location = changed.location
        key = changed.key
        cnew = changed.new
    end

    Client._cache = new
    _fireChanged(location, cnew or new, key)
    return new
end

function Client:SetKey(key, new)
    Client:Get()
    _assertIsClientReadOnly(key)
    Client._cache[key] = new
    _fireChanged("Key", new, key)
    return new
end

function Client:SetPath(path, new)
	Client:Get()
    local _pd = Client._cache
    Strings.doActionViaPath(path, _pd, function(parent, key, segments)
        if Client._defvar[segments[1]] then
            assert(not Client._defvar[segments[1]].clientReadOnly, "Cannot edit this value on the client.")
        end
        parent[key] = new
    end)
    Client._cache = _pd
    _fireChanged("Path", new, path)
    return Strings.convertPathToInstance(path, Client._cache)
end

--@summary Pushes the Client Cache to the Server Cache
function Client:Save()
    return RemoteFunction:InvokeServer("Set", Client._cache)
end

--@summary Set an Option Value, enforcing limits and type restrictions.
function Client:SetOptionValue(optionKey, valueKey, value)
    if not Shared:VerifyNewOptionValue(optionKey, valueKey, value) then
        return false, "Option value not verified."
    end
    return Client:SetPath("options." .. optionKey .. "." .. valueKey, value)
end

--@summary Listen for the changedBindable Event.
type Path = string
type Key = string
export type ChangedCallback = (changeLocation: "PlayerData" | "Key" | "Path", new: any, key: Path | Key) -> ()
export type PathChangedCallback = (new: any, path: string) -> ()
export type KeyChangedCallback = (new: any, key: string) -> ()
function Client:Changed(callback: ChangedCallback)
    local connection = {}
    connection.Connection = Client._changedEvent.Event:Connect(callback)
    connection.ServerConnection = game.Players.LocalPlayer:WaitForChild("PlayerDataChanged").OnClientEvent:Connect(callback)
    function connection:Disconnect()
        connection.Connection:Disconnect()
        table.remove(Client._listeners, connection.ID)
    end
    connection.ID = #Client._listeners + 1
    table.insert(Client._listeners, connection.ID, connection)
    return connection
end

--@summary Listen for a change on a path value
function Client:PathValueChanged(path: string, callback: PathChangedCallback)
    local connection = Client:Changed(function(changedLocation, new, key)
        if changedLocation == "Path" and key == path then
            callback(new, path)
        end
    end)
    return connection
end

--@summary Listen for a change on a key value
function Client:KeyValueChanged(_key: string, callback: KeyChangedCallback)
    local connection = Client:Changed(function(changedLocation, new, key)
        if changedLocation == "Key" and key == _key then
            callback(new, key)
        end
    end)
    return connection
end

--[[ Private ]]

--@param update boolean -- if true will set the Client Cache as got
function _getFromServer(update: boolean?)
    local success, result = pcall(function()return RemoteFunction:InvokeServer("Get")end)
    assert(success, result)
    if update then Client:Set(result) end
    return result
end

function _remoteClientEvent(action, ...)
    if not Client[action] then
        return
    end

    Client[action](Client, ...)
end

function _assertIsClientReadOnly(key)
    assert(not Client._defvar[key].clientReadOnly, "Cannot edit this value on the client.")
end

function _isClientListening()
    return #Client._listeners > 0
end

function _fireChanged(...)
    if _isClientListening() then
        Client._changedEvent:Fire(...)
    end
end

--@summary Will return before wait if possible
function _waitForCache()
    local _pd = Client._cache
    if _pd then return _pd end
    local t = tick() + clientWaitSec
    while not _pd and tick() < t do
        _pd = Client._cache
        task.wait()
    end
    return _pd
end

function _update()
    if not Players:FindFirstChild(player.Name) then
        conn[1]:Disconnect()
        conn[2]:Disconnect()
        return
    end
    if Client._changed and tick() >= Client._changed then
        Client._changed = false
        Client:Save()
    end
end

--@run
_getFromServer(true)
conn[1] = RemoteEvent.OnClientEvent:Connect(_remoteClientEvent)
conn[2] = RunService.RenderStepped:Connect(_update)

return Client
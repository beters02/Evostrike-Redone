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

local Client = {_cache = false, _changed = false}
Client._def, Client._defvar = Shared.def, Shared.defVar

function Client:Get(): Shared.PlayerData | false
    return _waitForCache()
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
    return new
end

function Client:SetAsync(new)
    Client._cache = new
    return new
end

function Client:SetKey(key, new)
    Client:Get()
    _isClientReadOnly(key)
    Client._cache[key] = new
    return new
end

function Client:SetPath(path, new)
    local _pd = Client._cache
    Client:Get()
    Strings.doActionViaPath(path, _pd, function(parent, key, segments)
        assert(not Client._defvar[segments[1]].clientReadOnly, "Cannot edit this value on the client.")
        parent[key] = new
    end)
    Client._cache = _pd
    return Strings.convertPathToInstance(path, Client._cache)
end

--@summary Pushes the Client Cache to the Server Cache
function Client:Save()
    return RemoteFunction:InvokeServer("Set", Client._cache)
end

--[[ Private ]]

--@param update boolean -- Update local cache?
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

function _isClientReadOnly(key)
    assert(not Client._defvar[key].clientReadOnly, "Cannot edit this value on the client.")
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
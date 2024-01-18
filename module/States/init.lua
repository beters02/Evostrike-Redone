--[[
    Reliable, replicated States.
    Initialied upon first require, must be initialized on both Client and Server.

    ------- Tutorial -------
    == Create a Replicated State ==

        - From any script -
    local stateProperties = {id = "TestState", replicated = true, clientReadOnly = false}
    local stateVariables = {test = false}
    local state = States:Create(stateProperties, stateVariables)
    state:set("test", true)

        - From another script -
    local state = States:Get("TestState")
    state:get("test") -- returns true

    ====

]]

-----------------------------------------------------------------------------------------
-- Set this to a higher value if you are consistently having "getCurrentReplicated" error.
-- This would be happening if the game you are running States on is a larger game.
local CLIENT_GET_WAIT_SEC = 3
-----------------------------------------------------------------------------------------

local isInitializing = true

export type States = {
    Create: (self: States, properties: StateProperties, defaultVar: table) -> (State),
    Get: (self: States, ID: string) -> (State)
}

export type State = {
    _variables: table,

    get: (self: State, key: string) -> (any),
    set: (self: State, key: string, variant: any) -> (any),
    changed: (self: State, key: string, previousValue: any, newValue: any) -> {Disconnect: () -> ()},
    properties: StateProperties
}

export type StateProperties = {
    id: string,
    replicated: boolean,
    clientReadOnly: boolean,
    owner: "Client" | "Server"
}

local RunService = game:GetService("RunService")
local RF = script.Events.RemoteFunction
local RE = script.Events.RemoteEvent
local BE = script.Events.BindableEvent

function getListener() return RunService:IsClient() and "Client" or "Server" end
function getSignalKeyForListener(listener) return listener == "Client" and "OnClientEvent" or "OnServerEvent" end
function getSignalFireKeyForSender(sender) return sender == "Client" and "FireServer" or "FireAllClients" end

function hardCopy(tab: table)
    local self = {}
    for i, v in pairs(tab) do
        self[i] = v
    end
    return self
end

--

local States = {}
local State = {}

--@module States
States = {}
States._cache = {storedStates = {}}
States.__index = function(tab, key)
    if key ~= "_stateCreateAsync" and isInitializing then
        repeat task.wait() until not isInitializing
    end
    return tab[key]
end

function States:Create(properties: StateProperties, defaultVar: table)
    if properties.replicated then
        if RunService:IsClient() then
            properties.owner = "Client"
            local success, response = RF:InvokeServer("_stateCreateAsync", properties, defaultVar)
            assert(success, response)
        else
            properties.owner = "Server"
            RE:FireAllClients("_stateCreateAsync", properties, defaultVar)
        end
    end

    return States:_stateCreateAsync(properties, defaultVar) :: State
end

function States:Get(ID: string)
    local state = States._cache.storedStates[ID] :: State
    if not state and RunService:IsClient() then
        local i = 0
        while not state and i < CLIENT_GET_WAIT_SEC do
            state = States._cache.storedStates[ID] :: State
            task.wait(1)
            i += 1
        end
    end
    return state
end

--

--@class State
State = {}
State.__index = State

function State.new(properties, defaultVariables)
    properties.owner = properties.owner or getListener()
    local self = setmetatable({}, State) :: State
    self.new = nil
    self.properties = properties :: StateProperties
    self._variables = hardCopy(defaultVariables)
    self._localListeners = {} -- { {callback} }
    self._globalListeners = {}
    return self
end

-- Get a value from the State
function State:get(key: string)
    return self._variables[key]
end

-- Set a value from the State
function State:set(key: string, new: any)
    if self.properties.replicated then
        return setReplicated(self, key, new)
    end
    local curr = self:get(key)
    local succ, result = pcall(setAsync, self, key, new)
    if succ then
        fireChanged(self, key, curr, result)
        return result
    end
    warn(result)
    return false
end

-- Get a Changed Connection from the State
-- callback = (key, curr, new)
function State:changed(callback)
    local listener = getListener()
    local listenerIndex = false
    local remove
    if listener == self.properties.owner then
        table.insert(self._localListeners, callback)
        listenerIndex = #self._localListeners
        remove = function()
            table.remove(self._localListeners, listenerIndex)
        end
    else
        listenerIndex = States:addGlobalListener(self.properties.id, callback)
        remove = function()
            States:removeGlobalListener(self.properties.id, listenerIndex)
        end
    end

    local conn = createListenerChangedConnection(self, listener, self.properties.owner, callback)
    print(conn)
    return {
        Disconnect = function() conn:Disconnect() remove() end
    }
end

--

function remoteMiddleware(action, ...)
    if action == "_stateSetAsync" then
        local state = ...
        if States:Get(state).properties.clientReadOnly then
            warn("State " .. tostring(state) .. " is clientReadOnly")
            return false
        end
    end
    return true
end

function initServerStatesForClient(statesToCreate)
    for _, st in pairs(statesToCreate) do
        States:_stateCreateAsync(st[1], st[2])
    end
    statesToCreate = nil
end

function setReplicated(self, key, new)
    if RunService:IsClient() then
        assert(not self.properties.clientReadOnly, "Client cannot edit State " .. self.properties.id) -- We check if clientReadOnly first on client, then on server to save on remote queue.
        local success, response = pcall(function()
            return RF:InvokeServer("_stateSetAsync", self.properties.id, key, new)
        end)
        assert(success, response)
        return response
    else
        local curr = self:get(key)
        RE:FireAllClients("_stateSetAsync", self.properties.id, key, new)
        fireChanged(self, key, curr, new)
        return setAsync(self, key, new)
    end
end

function setAsync(self, key, new)
    self._variables[key] = new
    return new
end

function fireChanged(self, key, curr, new)
    if #self._localListeners > 0 then
        BE:Fire("__Changed__", self.properties.id, key, curr, new)
    end
    if #self._globalListeners > 0 then
        local fireKey = getSignalFireKeyForSender(getListener())
        RE[fireKey]("__Changed__", self.properties.id, key, curr, new)
    end
end

function doStatesHandler(action, ...)
    if States[action] then
        return States[action](States, ...)
    end
end

function doStatesHandlerServer(_, action, ...)
    assert(States[action], "Action " .. tostring(action) .. " not found")
    assert(remoteMiddleware(action, ...), "Remote did not pass middleware.")
    return States[action](States, ...)
end

--Creates a BindableEvent or RemoteEvent Connection depending on who's listening
function createListenerChangedConnection(self, listener, owner, callback)
    local function eventHandler(reason, state, key, previousValue, newValue)
        if reason ~= "__Changed__" then return end
        if state ~= self.properties.id then return end
        callback(key, previousValue, newValue)
    end
    if listener ~= owner then
        return RE[getSignalKeyForListener(listener)]:Connect(eventHandler)
    end
    return BE.Event:Connect(eventHandler)
end

function States:_stateCreateAsync(properties, defaultVar)
    local _state = State.new(properties, defaultVar)
    States._cache.storedStates[properties.id] = _state
    return _state :: State
end

function States:_stateSetAsync(id, key, new)
    return setAsync(States:Get(id), key, new)
end

function States:_getCurrentReplicated()
    local _st = {}
    for _, s in pairs(States._cache.storedStates) do
        if s.properties.replicated then
            table.insert(_st, {s.properties, s._variables})
        end
    end
    return _st
end

function States:addGlobalListener(state, callback)
    local listener = getListener()
    if listener == "Client" then
        return RF:InvokeServer("addGlobalListenerAsync", state, callback)
    else
        return RF:InvokeClient("addGlobalListenerAsync", state, callback)
    end
end

function States:removeGlobalListener(state, index)
    local listener = getListener()
    if listener == "Client" then
        return RF:InvokeServer("removeGlobalListenerAsync", state, index)
    else
        return RF:InvokeClient("removeGlobalListenerAsync", state, index)
    end
end

function States:addGlobalListenerAsync(state, callback)
    state = States:Get(state)
    table.insert(state._globalListeners, callback)
    return #state._globalListeners
end

function States:removeGlobalListenerAsync(state, index)
    state = States:Get(state)
    table.remove(self._globalListeners, index)
end

--

--@run [[
if RunService:IsServer() then
    RF.OnServerInvoke = doStatesHandlerServer
    RE.OnServerEvent:Connect(doStatesHandlerServer)
    BE.Event:Connect(doStatesHandler)
    isInitializing = false
elseif RunService:IsClient() then
    local statesToCreate = RF:InvokeServer("_getCurrentReplicated")
    assert(statesToCreate, "Could not getCurrentReplicated! Did you connect to this module on the server?")
    initServerStatesForClient(statesToCreate)
    RE.OnClientEvent:Connect(doStatesHandler)
    BE.Event:Connect(doStatesHandler)
    RF.OnClientInvoke = doStatesHandler
    isInitializing = false
end
-- ]]

return States :: States
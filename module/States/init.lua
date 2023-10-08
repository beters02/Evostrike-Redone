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

export type States = {
    Create: (self: States, properties: StateProperties, defaultVar: table) -> (State),
    Get: (self: States, ID: string) -> (State)
}

export type State = {
    _variables: table,

    get: (self: State, key: string) -> (any),
    set: (self: State, key: string, variant: any) -> (any),
    properties: StateProperties
}

export type StateProperties = {
    id: string,
    replicated: boolean,
    clientReadOnly: boolean
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RF = script.Events.RemoteFunction
local RE = script.Events.RemoteEvent

local Util = {}
function Util.hardCopy(tab: table)
    local self = {}
    for i, v in pairs(tab) do
        self[i] = v
    end
    return self
end

function Util.fireAllClientsExcept(remote, player, ...)
    for _, plr in ipairs(Players:GetPlayers()) do
        if player ~= plr then
            remote:FireClient(...)
        end
    end
end

--@class [[
local State = {}
State.__index = State

function State.new(properties, defaultVariables)
    local self = setmetatable({}, State) :: State
    self.new = nil
    self.properties = properties :: StateProperties
    self._variables = Util.hardCopy(defaultVariables)
    return self
end

function State:get(key: string)
    return self._variables[key]
end

function State:set(key: string, new: any)
    if self.properties.replicated then
        if RunService:IsClient() then
            assert(not self.properties.clientReadOnly, "Client cannot edit State " .. self.properties.id)
            local success, response = pcall(function()
                return RF:InvokeServer("_stateSetAsync", self.properties.id, key, new)
            end)
            assert(success, response)
            return response
        else
            RE:FireAllClients("_stateSetAsync", self.properties.id, key, new)
        end
    end

    return self:setAsync(key, new)
end

function State:setAsync(key: string, new: any)
    self._variables[key] = new
    return new
end
-- ]]

--@module [[
local States = {}
States._cache = {storedStates = {}}

function States:Create(properties: StateProperties, defaultVar: table)
    if properties.replicated then
        if RunService:IsClient() then
            local success, response = RF:InvokeServer("_stateCreateAsync", properties, defaultVar)
            assert(success, response)
        else
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
-- ]]

--@module_private [[
function States:_stateCreateAsync(properties, defaultVar)
    local _state = State.new(properties, defaultVar)
    States._cache.storedStates[properties.id] = _state
    return _state :: State
end

function States:_stateSetAsync(id, key, new)
    return States:Get(id):setAsync(key, new)
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
-- ]]

--@run [[
if RunService:IsServer() then
    local function ServerInvoke(_, action, ...)
        assert(States[action], "Action " .. tostring(action) .. " not found")
        return States[action](States, ...)
    end
    RF.OnServerInvoke = ServerInvoke
elseif RunService:IsClient() then
    RE.OnClientEvent:Connect(function(action, ...)
        if States[action] then
            States[action](States, ...)
        end
    end)

    local statesToCreate = RF:InvokeServer("_getCurrentReplicated")
    assert(statesToCreate, "Could not getCurrentReplicated! Did you connect to this module on the server?")

    for _, st in pairs(statesToCreate) do
        States:_stateCreateAsync(st[1], st[2])
    end
    statesToCreate = nil
end
-- ]]

return States :: States
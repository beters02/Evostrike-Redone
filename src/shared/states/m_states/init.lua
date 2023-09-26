local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local mainrf = ReplicatedStorage:WaitForChild("states").remote.mainrf

local states = {}

--[[
    Main
]]

-- Get a State (class)
function states.State(state: string)
    return RunService:IsClient() and states._clientClassStore[state] or states._serverClassStore[state]
end

-- Get a State's Variable
function states.GetStateVariable(stateName: string, key: string, player: Player?)
    -- Get from Server
    if RunService:IsServer() then

        local store = states._serverClassStore[stateName]
        if store then
            -- if server store exists, return server cached key
            return store:get(key)
        end

        if not player then return end --TODO: player not specified and serverstore not found error

        -- if server store doesn't exist, it must be a client store or non existent.
        -- invoke client for store here
        return mainrf:InvokeClient(player, "getVar", stateName, key)
    end
    
    -- Get from Client
    local store = states._clientClassStore[stateName]
    if store then
         -- if client store exists, return client cached key
        return store:get(key)
    end

    -- if client store doesn't exist, it must be a server store or non existent.
    -- invoke server for store here
    return mainrf:InvokeServer("getVar", stateName, key)
end

-- Set a State's Variable
function states.SetStateVariable(stateName: string, key: string, value: any, player: Player?)
    if RunService:IsServer() then
        local store = states._serverClassStore[stateName]
        if store then
            store:set(key, value)
            return store:get(key)
        end

        if not player then return end --TODO: player not specified and serverstore not found error

        return mainrf:InvokeClient(player, "setVar", stateName, key, value)
    end
    
    --IsClient
    local store = states._clientClassStore[stateName]
    if store then
        store:set(key, value)
        return store:get(key)
    end

    return mainrf:InvokeServer("setVar", stateName, key, value)
end

--[[
    Script Functions
]]

-- Get classes from a given class storage location
local function util_getClassesFromLocation(location: any, base: table)
    local new = {}

    -- initialize all of the classBase's children which are classes
    for _, nclass in pairs(location:GetChildren()) do
        local req = require(nclass)
        new[req.stateName] = base.new(req.stateName, req.var)
        
        -- initialize functions
        for i, v in pairs(req) do

            if i ~= "stateName" and i ~= "var" then
                new[req.stateName][i] = v
            end
        end
    end

    return new
end

-- Initialize server states
local function server_init_serverStateClasses()
    local statesFolderServer = game:GetService("ServerScriptService"):FindFirstChild("states")
    if not statesFolderServer then return end

    local classloc = statesFolderServer
    local class = require(ReplicatedStorage:WaitForChild("c_statePlayerBase"))

    -- initialize module's server class storage variable
    local _scs

    -- init classes
    _scs = util_getClassesFromLocation(classloc, class)
    states._serverClassStore = _scs
end

-- Initialize Client States
local function client_init_clientStateClasses()
    local classloc = ReplicatedStorage:WaitForChild("states"):WaitForChild("c_clientStateBase")
    local class = require(classloc)

    -- initialize module's client class storage variable
    local _ccs

    -- init classes
    _ccs = util_getClassesFromLocation(classloc, class)
    states._clientClassStore = _ccs
end

--[[
    Script Logic
]]

if RunService:IsServer() then server_init_serverStateClasses() end
if RunService:IsClient() then client_init_clientStateClasses() end

return states
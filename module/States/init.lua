local RunService = game:GetService("RunService")
-- [[ States Singleton Module ]]

--[[
    A "State" is a Class that will contain a table values that remain
    consistent globally, and can be set and got from anywhere.

    States are not replicated by default, you have to set replicated = true when creating

    

    In this current stage I think the module is quite unreliable when replicating because it only Fire's a RemoteEvent once.
    I would rather replication be through the RemoteFunction and listening to responses on a seperate thread.

    On second thought, replication does not actually work at all right now since we need to create listeners on both the Server and Client for when a value is to be replicated.
]]

export type State = {
    id: string,
    replicated: boolean,
    values: table,
    changedBindable: BindableEvent,
    changedRemote: RemoteEvent | false,

    get: (self: State, key: string) -> (any),
    set: (self: State, key: string, value: any) -> (any)
}

-- Module
local States = {}
States.Stored = {}
States.Module = script
States.RemoteEvent = script:WaitForChild("RemoteEvent")
States.RemoteFunction = script:WaitForChild("RemoteFunction")

-- Class
local State = {}
State.__index = State

-- [[ PUBLIC MODULE FUNCTIONS ]]

--@summary Create a Custom State
function States:CreateState(id: string, replicated: boolean, values: table)
    return State.new(id, replicated, values)
end

--@summary Get a Stored State by ID
function States:GetState(id: string)
    return States.Stored[id]
end

-- [[ CREATE STATES ]]

--@summary Create a new state.
function State.new(id: string, replicated: boolean, values: table)
    assert(not States.Stored[id], "Cannot create two of the same state. " .. tostring(id))

    local self: State = {
        id = id,
        replicated = replicated,
        values = values
    }
    
    if RunService:IsClient() and replicated then -- server creates replicated objs
        self.changedBindable, self.changedRemote = States.RemoteFunction:InvokeServer("NewState", id, replicated, values)
    else
        self.changedBindable = Instance.new("BindableEvent", States.Module)
        self.changedRemote = replicated and RunService:IsServer() and Instance.new("RemoteEvent", States.Module)
    end

    if RunService:IsServer() and replicated then
        States.Remote:FireAllClients("NewState", id, replicated, values, self.changedBindable, self.changedRemote)
    end

    States.Stored[id] = setmetatable(self, State)
    return States.Stored[id]
end

--@summary Get a value from a State's value key.
function State:get(key: string)
    return self.values[key]
end

--@summary Set a value from a State's value key.
function State:set(key: string, value: any)
    local succ, err = pcall(function()
        self.values[key] = value
    end)
    
    if not succ then
        warn("Could not set state " .. tostring(key) .. " " .. tostring(err))
        return
    end

    self.changedBindable:Fire(key, value)

    if self.replicated then
        if RunService:IsServer() then
            self.changedRemote:FireAllClients(key, value)
        else
            self.changedRemote:FireServer(key, value)
        end
    end

    return self.values[key]
end

--@summary Listen to the Changed Bindable Event
--@param once: boolean          - Listen only once?
--@param listenKey: string?     - Define key if listening for specific key value change, otherwise put false
--@param callback: function     - The function ran on Event Fired
function State:listenChangedBindable(once: boolean, listenKey: string | false, callback: (key: string, value: any) -> ()): RBXScriptConnection
    local conn
    conn = self.changedBindable.Event:Connect(function(key, value)
        if listenKey and listenKey ~= key then return end
        callback(key, value)
        if once then
            conn:Disconnect()
        end
    end)
    return conn
end

--@summary Listen to the Changed Remote Event (replicated state only)
function State:listenChangedRemote(once: boolean, listenKey: string | false, callback: (key: string, value: any) -> ()): RBXScriptConnection
    local conn

    if RunService:IsClient() then
        conn = self.changedRemote.OnClientEvent:Connect(function(key, value)
            if listenKey and listenKey ~= key then return end
            callback(key, value)
            if once then
                conn:Disconnect()
            end
        end)
    elseif RunService:IsServer() then
        conn = self.changedRemote.OnServerEvent:Connect(function(_, key, value)
            if listenKey and listenKey ~= key then return end
            callback(key, value)
            if once then
                conn:Disconnect()
            end
        end)
    end
    
    return conn
end

-- [[ INIT DEFAULT CLASSES & REQUIRE SCRIPT ]]

if RunService:IsServer() then
    -- Replicated State Creation
    States.RemoteFunction.OnServerInvoke = function(_, action, ...)
        if action == "NewState" then
            local id, replicated, values = ...
            local _state = States.new(id, replicated, values)
            return _state.changedBindable, _state.changedRemote
        end
    end
elseif RunService:IsClient() then

    --[[Movement]]
    State.new("Movement", false, {
        grounded = false,
        landing = false,
        crouching = false
    })

    --[[PlayerActions]]
    State.new("PlayerActions", false, {
        shooting = false,
        reloading = false,
        weaponEquipped = false,
        weaponEquipping = false,
        grenadeThrowing = false
    })

    --[[UI]]
    local UI = State.new("UI", false, {
        openUIS = {}
    })

    function UI:addOpenUI(uiName, ui, mouseIconEnabled)
        if not uiName then warn("Must specifiy UI name.") return false end
    
        -- we dont want to add the same UI twice here
        if self.values.openUIs[uiName] then
            warn("C_UI Cannot open the same UI twice. " .. tostring(uiName))
            return false
        end
    
        -- set as new table so changed event fires
        local new = self.values.openUIs
        new[uiName] = {UI = ui, MouseIconEnabled = mouseIconEnabled or false}
        return self:set("openUIs", new)
    end
    
    -- Remove an open UI from the state data
    function UI:removeOpenUI(uiName)
        -- set as new table so changed event fires
        local new = self.values.openUIs
        new[uiName] = nil
        return self:set("openUIs", new)
    end
    
    function UI:hasOpenUI()
        for _, v in pairs(self:get("openUIs")) do
            if v then return true end
        end
        return false
    end
    --[[END UI]]
end

return States
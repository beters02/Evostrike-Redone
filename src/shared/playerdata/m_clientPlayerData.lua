--[[ Client Player Data is the module used for storing Player-Specific playerdata ]]

local RunService = game:GetService("RunService")
if RunService:IsServer() then error("m_clientPlayerData: You cannot use this module on the server.") end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.shfc_strings.Location)
local Remotes = ReplicatedStorage.PlayerData:WaitForChild("remote")

-- init core playerdata variables
local DefaultPlayerData, DefaultPlayerDataMinMax = Remotes.sharedPlayerDataRF:InvokeServer("GetDefault")
DefaultPlayerData = DefaultPlayerData and require(DefaultPlayerData)
DefaultPlayerDataMinMax = DefaultPlayerDataMinMax and require(DefaultPlayerDataMinMax)
if not DefaultPlayerData then warn("COULDNT FIND DEF PLAYERDATA") end

local module = {}
module.isInit = false

-- initialize the player's playerdata module
function module.initialize()
    module.stored = module:GetAsync()
    module.changed = Instance.new("BindableEvent")
    module.changed.Parent = ReplicatedStorage:WaitForChild("temp")
    
    module.isListening = {}
    
    module.isInit = true
    return module
end

-- verify that the module is initialized
-- will wait for initialization if not isInit and doWait
local _verifyMaxTime = 10
function module.verify(doWait: boolean)
    if not module.isInit then
        if doWait then
            local _t = tick() + _verifyMaxTime
            repeat task.wait() until module.isInit or tick() >= _t
            return module.isInit or false
        end

        return false
    end

    return true
end

--[[
    @title Get

    @summary Get a table key using PathString. Example: "options.keybinds.weaponPrimary" Only gets from local cache.
    Automatically waits for playerdata to be initalized if it has not been already.
    If you're trying to get the stored value, call GetAsync.
]]
function module:Get(path: string)
    if not module.stored then repeat task.wait() until module.stored end
    return Strings.convertPathToInstance(path, module.stored)
end

--[[
    @title GetAsync
    @summary Get a table key from the server using PathString.
]]

function module:GetAsync(path: string?)
    local _stored = Remotes.sharedPlayerDataRF:InvokeServer("Get")
    return path and Strings.convertPathToInstance(path, _stored) or _stored
end

--[[
    @title Set

    @summary Set a table key using PathString. Only changes local cache until playerdata:Save() is called.
]]
function module:Set(path: string, value: any, dontFireChanged: boolean)

    -- if we can't set, we will use these var
    local change, err = true, false

    -- set some values
    local tableParent, parentKey
    
    Strings.doActionViaPath(path, module.stored, function(gotTableParent, key, segments)
        local _current = gotTableParent[key]

        -- verify type
        if type(value) ~= type(_current) then
            change = false
            err = "Couldn't update option: Invalid type signature"
        end

        -- verify set min/max
        local minMax = Strings.convertPathToInstance(path, DefaultPlayerDataMinMax, true)
        if change and minMax and minMax ~= "nil" then
            if value < minMax.min or value > minMax.max then
                change = false
                err = "Couldn't update option: Value too low or too high"
                warn(err)
            end
        end

        -- currentValue, value(table)'s parent, the name of the key that is the value to its parent, path seperated into string
        if change then
            _, tableParent, parentKey, _ =  _current, gotTableParent, key, segments
        end
    end)

    if change then

        -- set the key from its parent table
        tableParent[parentKey] = value

        -- fire changed with path and new value
        if not dontFireChanged then
            module.changed:Fire(path, value)
        end

    end

    return value, change, err
end

--[[
    @title Insert

    @summary Insert a value into a table using PathString. Only changes local cache until playerdata:Save() is called.
]]

function module:Insert(path: string, value: any)
    local _table = self:Get(path)

    if type(_table) ~= "table" then error("Cannot insert into a " .. type(_table)) end
    table.insert(_table, value)

    -- we're just trying to save on mem
    _table = table.pack(self:Set(path, _table, true))
    if not _table or not _table[1] then return end

    -- fire changed event with insert
    module.changed:Fire(path, value, {isInsert = true}) -- path, value, properties

end

--[[
    @title Save

    @summary Save the cached data to the server DataStore
]]
function module:Save()
    --if RunService:IsStudio() then return true end
    return Remotes.sharedPlayerDataRF:InvokeServer("Set", module.stored, true)
end

--[[
    @title Changed

    @summary Listen to value changes in specified path.

    @return RBXScriptConnection
]]
function module:Changed(path: string, callback: (newValue: any, ...any) -> ())
    if not module.changed then repeat task.wait() until module.changed end
    return module.changed.Event:Connect(function(returnedPath: string, newValue: any, ...)
        if path == returnedPath then
            callback(newValue, ...)
        end
    end)
end

function module:IsInit() return self.isInit end
function module:WaitForInit() repeat task.wait() until self.isInit return self.Init end

return module
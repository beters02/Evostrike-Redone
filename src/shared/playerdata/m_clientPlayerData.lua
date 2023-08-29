local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
if RunService:IsServer() then error("m_clientPlayerData: You cannot use this module on the server.") end

local Remotes = ReplicatedStorage:WaitForChild("playerdata"):WaitForChild("remote")

local DefaultPlayerData, DefaultPlayerDataMinMax = Remotes.sharedPlayerDataRF:InvokeServer("GetDefault")
DefaultPlayerData = DefaultPlayerData and require(DefaultPlayerData)
DefaultPlayerDataMinMax = DefaultPlayerDataMinMax and require(DefaultPlayerDataMinMax)
if not DefaultPlayerData then warn("COULDNT FIND DEF PLAYERDATA") end

local module = {}
module.isInit = false

function module.initialize()
    module.stored = module.GetFromStored()
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

function module.get(optionKey: string, dataKey: string)
    if not module.verify(true) then return end
    return module.stored.options[optionKey][dataKey]
end

function module.set(optionKey: string, dataKey: string, value: any)
    if not module.verify(true) then return end

    local change = true
    local err = false

    if type(value) ~= type(module.stored.options[optionKey][dataKey]) then
        change = false
        err = "Couldn't update option: Invalid type signature"
        warn(err)
    elseif DefaultPlayerDataMinMax.options[optionKey] and DefaultPlayerDataMinMax.options[optionKey][dataKey] then
        if value < DefaultPlayerDataMinMax.options[optionKey][dataKey].min or value > DefaultPlayerDataMinMax.options[optionKey][dataKey].max then
            change = false
            err = "Couldn't update option: Value too low or too high"
            warn(err)
        end
    end
    
    if change then
        module.stored.options[optionKey][dataKey] = value
        module.changed:Fire(value, optionKey, dataKey)
    end
    
    return module.stored.options[optionKey][dataKey], change, err
end

function module.listenForChange(optionKey: string, dataKey: string, callback: (any) -> ())
    if not module.isListening[optionKey] then
        module.isListening[optionKey] = {}
    end

    if not module.isListening[optionKey][dataKey] then
        module.isListening[optionKey][dataKey] = true
    end

    return {
        Connection = module.changed.Event:Connect(function(newValue, noptionKey, ndataKey)
            if noptionKey == optionKey and ndataKey == dataKey then
                callback(newValue)
            end
        end),
        Disconnect = function(self)
            module.isListening[optionKey][dataKey] = false
            self.Connection:Disconnect()
        end
    }

end

--

function module.GetFromStored()
    return Remotes.sharedPlayerDataRF:InvokeServer("Get")
end

function module.UpdateToStoredFromCache()
    return Remotes.sharedPlayerDataRF:InvokeServer("Set", module.stored)
end

return module
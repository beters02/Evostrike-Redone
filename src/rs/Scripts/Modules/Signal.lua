--[[

    local s = Signal.CreateSignal(name: string)
    s.Connect(function() end)
    s.Disconnect()

    -- diferent script
    local s = Signal.GetSignal(name: string)
    s.Fire(arg)

    Maybe add automatic cacheing
    If a signal remains unconnected for some time then move it to "Cache", once it is connected move it back to stored

]]

local RunService = game:GetService("RunService")

local Signal = {}
Signal.__index = Signal
Signal._currentIDIndex = 0
Signal._stored = {}

function Signal.CreateSignal(SignalName, forceDeleteOld)
    if Signal._stored[SignalName] then
         if forceDeleteOld then
             Signal._stored[SignalName].Destroy()
         else return Signal._stored[SignalName] end
    end

    local t = setmetatable({}, Signal)
    t.__index = t
    t._id = SignalName
    t._connected = false
    t._execute = false
    t._currentRunFunction = nil
    t._currentRunArguments = nil

    t.Connect = function(functionToExecute)
        t._connected = true
        t._currentRunFunction = functionToExecute
        return t
    end

    t.Disconnect = function()
        t._connected = false
        t._currentRunFunction = nil
    end

    t.Fire = function(...)
        t._execute = true
        t._currentRunArguments = table.pack(...)
    end

    t.FireIfListening = function(...)
        if not t._connected then return end
        t.Fire(...)
    end
    
    t.Destroy = function()
        if t._connected then t.Disconnect() end
        Signal._stored[SignalName] = nil
    end

    Signal._stored[SignalName] = t
    return t
end

function Signal.GetSignal(SignalName)
    if Signal._stored[SignalName] then return Signal._stored[SignalName] end
    return false
end

function Signal.WaitForSignal(SignalName, timeout)
    local nt = tick() + (timeout or 3)
    repeat task.wait() until Signal._stored[SignalName] or tick() >= nt
    if Signal._stored[SignalName] then return Signal._stored[SignalName] end
    return false
end

--#region PRIVATE SCRIPT FUNCTIONS

function Signal._update()
    for i, signal in pairs(Signal._stored) do
        if signal._connected and signal._execute then
            signal._execute = false
            task.spawn(function()
                signal._currentRunFunction(table.unpack(signal._currentRunArguments))
            end)
        end
    end
end

--#endregion

if RunService:IsServer() then
    RunService.Heartbeat:Connect(Signal._update)
elseif RunService:IsClient() then
    RunService.RenderStepped:Connect(Signal._update)
end

return Signal
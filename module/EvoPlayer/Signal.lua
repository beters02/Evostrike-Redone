local RunService = game:GetService("RunService")
if RunService:IsClient() then error("This module is meant to be used on the server.") end

export type SignalConnection = {
    ID: number,
    Callback: (...any) -> (...any),
    Disconnect: (table) -> (),
    Once: boolean,
}

export type Signal = {
    Connect: (table, callback: (...any) -> (...any)) -> (SignalConnection),
    Once: (table,  callback: (...any) -> (...any)) -> (SignalConnection),
    Disconnect: (table) -> (),
    Fire: (table, ...any) -> (),
    FireRemoveDelay: number
}

local Signal = {}

function Signal.new(fireRemoveDelay: number?)
    local self = {}
    self.__index = self

    self._connections = {}
    self._firing = false
    self._args = false
    self._fireRemoveDelay = fireRemoveDelay or 0.1

    function self:Connect(callback, once) -- returns a SignalConnection
        local ID = #self._connections + 1
        local sc: SignalConnection = {
            ID = ID,
            Callback = callback,
            Disconnect = function(tab) table.remove(self._connections, ID) end,
            Once = once or false,
        }
        table.insert(self._connections, ID, sc)
        if not self._connections.main and #self._connections >= 0 then
            self._connections.main = RunService.Heartbeat:Connect(function()
                if #self._connections == 0 then self:Disconnect() end
                if not self._firing then return end
                self._firing = false

                for i, v in pairs(self._connections) do
                    if i == "main" then continue end
                    v = v :: SignalConnection
                    v.Callback(table.unpack(self._args))
                    if v.Once then
                        v.Disconnect()
                        v = nil
                    end
                end
            end)
        end
        return sc
    end

    function self:Once(callback)
        return self:Connect(callback, true)
    end

    function self:Disconnect()
        for _, v in pairs(self._connections) do
            v:Disconnect()
        end
        self._connections = {}
    end

    function self:Fire(...)
        self._args = table.pack(...)
        self._firing = true
        task.delay(self._fireRemoveDelay, function()
            if self._firing then
                self._firing = false
            end
        end)
    end

    return self :: Signal
end

return Signal
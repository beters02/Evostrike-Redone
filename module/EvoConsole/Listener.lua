local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local listener = {
    connections = false
}

function listener.init(Console)
    if listener.connections then warn("Console listener already initialized") return end
    listener = setmetatable(listener, {__index = Console})
    listener.connections = {}
    listener:_connectListener()
end

function listener:_connectListener()
    self.Bridge.OnServerInvoke = function(...)
        return self:BridgeInvoke(...)
    end
end

function listener:_disconnectListener()
    self.Bridge.OnServerInvoke = nil
end

--

function listener:BridgeInvoke(player, action, ...)
    if action == "instantiateConsole" then
        return self:_instantiateConsole(player)
    end

    return false
end

return listener
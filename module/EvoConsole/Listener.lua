local RunService = game:GetService("RunService")
if RunService:IsClient() then return {} end

local StoredMapIDs = require(game:GetService("ServerStorage"):WaitForChild("Stored"):WaitForChild("MapIDs"))
local TeleportService = game:GetService("TeleportService")

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
    elseif action == "MapCommand" then
        
        local mapName, gamemode, players = ...
        local mapID = StoredMapIDs.GetMapId(mapName)

        if not mapID then
            return false, "Map " .. " does not exist"
        end

        local success, err = pcall(function()
            local priv = TeleportService:ReserveServer(mapID)
            TeleportService:TeleportToPrivateServer(mapID, priv, players, "", {RequestedGamemode = gamemode})
        end)

        return success, err
    end

    return false
end

return listener
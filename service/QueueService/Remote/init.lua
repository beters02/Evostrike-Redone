local TeleportService = game:GetService("TeleportService")
local StoredMapIDs = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))

local requestActions = {
    Add = function(self, player, ...)
        if not self:IsRunning() then return false end
        if not self.Manager.Queues[...] then return false end
        return self.Manager.Queues[...]:AddPlayer(player)
    end,
    Remove = function(self, player, ...)
        if not self:IsRunning() then return false end
        if not self.Manager.Queues[...] then return false end
        return self.Manager.Queues[...]:RemovePlayer(player)
    end,
    PrintAll = function(self)
        for i, v in pairs(self.Manager.Queues) do
            if type(v) ~= "table" then continue end
            if v.isQueueClass then
                v:PrintAllPlayers()
            end
        end
    end,
    ClearAll = function(self)
        for i, v in pairs(self.Manager.Queues) do
            if type(v) ~= "table" then continue end
            if v.isQueueClass then
                v:ClearAllPlayers()
            end
        end
    end,
    TeleportPrivateSolo = function(self, player) -- todo: get mapid. for now its warehouse
        TeleportService:TeleportToPrivateServer(14504041658, TeleportService:ReserveServer(StoredMapIDs.mapIds.warehouse.id), {player}, false, {RequestedGamemode = "Range"})
        return true
    end
}

local module = {}

-- this is a little hacky but we'll try it
--[[module.__call = function(self, ...)
    local _t = table.pack(...)
    local player, action = _t[1], _t[2]
    print(player, action)
    table.remove(_t, 1)
    table.remove(_t, 1)
    if not requestActions[action] then return false end
    return requestActions[action](self, player, table.unpack(_t))
end]]

--[[module.request = function(self, player, action, ...)
    if not requestActions[action] then return false end
    return requestActions[action](self, player, ...)
end]]

return function(self, player, action, ...)
    if not requestActions[action] then return false end
    return requestActions[action](self, player, ...)
end
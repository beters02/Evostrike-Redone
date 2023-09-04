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
    end
}

return function(self, player, action, ...)
    if not requestActions[action] then return false end
    return requestActions[action](self, player, ...)
end
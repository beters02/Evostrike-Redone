--[[
    Responsible for managing all QueueClasses
]]

local QueueManager = {}
QueueManager.__index = QueueManager
QueueManager.Queues = {}

function QueueManager:StartManager(QueueService)
    self:StartAllQueues(QueueService)
end

function QueueManager:StartQueue(QueueService, QueueName)
    local module = require(QueueService.__location.QueueManager.QueueClasses.base).new(QueueName)
    module:Start()
    self.Queues[QueueName] = module
end

function QueueManager:StopQueue(QueueService, QueueName)
    self.Queues[QueueName]:Stop()
end

function QueueManager:StartAllQueues(QueueService)
    for i, v in pairs(QueueService.__location.QueueManager.QueueClasses:GetChildren()) do
        if v.Name == "base" then continue end -- Ignore BaseClass
        self:StartQueue(QueueService, v.Name)
    end
end

function QueueManager:StopAllQueues()
    for i, v in pairs(self.Queues) do
        v:Stop()
    end
end

return QueueManager
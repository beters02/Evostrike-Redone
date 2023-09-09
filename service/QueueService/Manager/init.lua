--[[
    Responsible for managing all QueueClasses
]]

local QueueManager = {}
QueueManager.__index = QueueManager
QueueManager.Queues = {}

function QueueManager:StartManager(QueueService)
    self:StartAllQueues(QueueService)
end

function QueueManager:StopManager()
    self:StopAllQueues()
end

--

function QueueManager:StartQueue(QueueService, QueueName)
    print('Starting queue ' .. QueueName)

    print(QueueService.__location.Class.base)
    local module, err = require(QueueService.__location.Class.base).new(QueueName)
    print(module)
    module:Connect()

    print('Conected')

    self.Queues[QueueName] = module
end

function QueueManager:StopQueue(QueueService, QueueName)
    self.Queues[QueueName]:Stop()
end

--

function QueueManager:StartAllQueues(QueueService)
    print('STarting all queues')
    for i, v in pairs(QueueService.__location.Class:GetChildren()) do
        if v.Name == "base" then continue end -- Ignore BaseClass
        self:StartQueue(QueueService, v.Name)
    end
end

function QueueManager:StopAllQueues()
    for i, v in pairs(self.Queues) do
        if not v.IsQueue then continue end
        v:Stop()
    end
end

return QueueManager
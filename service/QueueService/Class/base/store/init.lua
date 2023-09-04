local DataStoreService = game:GetService("DataStoreService")

--[[
    Queue Store interface
]]

local _queueStorePrefix = "QueueService_"
local _initRetries = 5

local store = {}
store.__index = store
store.__location = game:GetService("ReplicatedStorage").Services.QueueService.Class.base.store
store.process = require(store.__location.actionProcess)
store.process:Connect()

--[[
    Initialize store module class for queue
]]

function store.new(QueueName)
    local self = {}
    self.Name = QueueName
    return setmetatable(self, store)
end

--[[
    Initialize store on server and grab queue's stores from DataStore
]]
function store:Init()

    print('2')

    -- init datastore var
    self.datastore = store.process:Wrap(function()
        return DataStoreService:GetOrderedDataStore(_queueStorePrefix .. self.Name)
    end)

    print(self.datastore)

    if not self.datastore then
        error("Could not load queue " .. self.Name .. ". Datastore not loaded.")
    end
    print('2')
    -- update last result
    self:Get()
end

--[[
    Safely get the value of the datastore
]]
function store:Get()
    self.dsLastResult = store.process:Wrap(function()
        return self.datastore:GetSortedAsync(true, 100):GetCurrentPage()
    end)
    return self.dsLastResult
end

--[[
    Safely "add" an index to the store
]]
function store:Add(key: string, value: number) -- key: playerName, value: slot
    return store.process:Wrap(function()
        return pcall(function() -- we use a pcall here because SetAsync doesnt return anything i dont think
            self.datastore:SetAsync(key, value)
        end)
    end)
end

--[[
    Safely remove a value from the datastore
]]
function store:Remove(value: string)
    return store.process:Wrap(function()
        return pcall(function()
            self.datastore:RemoveAsync(value)
        end)
    end)
end

function store:Save()
    return store.process:Wrap(function()
        return pcall(function()
            self.datastore:SaveAsync()
        end)
    end)
end

return store
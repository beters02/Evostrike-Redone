local DataStoreService = game:GetService("DataStoreService")

--[[
    Queue Store interface
]]

local _queueStorePrefix = "QueueService_"
local _initRetries = 5

local store = {}
store.__location = game:GetService("ReplicatedStorage").Services.QueueService.Class.base.store

store.types = require(store.__location.types)
store.process = require(store.__location.actionProcess)

--[[
    Initialize store module class for queue
]]

function store.new()
    return setmetatable({}, store)
end

--[[
    Initialize store on server and grab queue's stores from DataStore
]]
function store:Init()

    -- init datastore var
    self.datastore = store.process:Wrap(
        function()
            return DataStoreService:GetOrderedDataStore(_queueStorePrefix .. self.Name)
        end,
        table.pack()
    )

    if not self.datastore then
        error("Could not load queue " .. self.Name .. ". Datastore not loaded.")
    end

    -- update last result
    self:Get()
end

--[[
    Safely get the value of the datastore
]]
function store:Get()
    self.dsLastResult = store.process:Wrap(
        function()
            return self.datastore:GetSortedAsync(true, 100):GetCurrentPage()
        end,
        table.pack()
    )
    print(self.dsLastResult)
    return self.dsLastResult
end

--[[
    Safely set the value of the datastore
]]

function store:Set(new)
    
end

--[[
    Safely add value to datastore table
]]

function store:AddToTable()
    
end

--[[
    Safely remove value from datastore table
]]

function store:RemoveFromTable()
    
end


return store
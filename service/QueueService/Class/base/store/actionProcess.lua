--[[
    When using datastore, use this "process" module to queue actions and not over request.
    Will automatically do 3 retries.

    Use:
    

    -- no argument variables:
    local data = process:Wrap(function()
        return datastore:Get()
    end)


    -- if we have access to the argument variables now, we can use this method:
    local result = process:Wrap(function()
        return module:Function(arg1, arg2)
    end)


    -- if we dont have access or the argument variables will be changing then we can use this method:
    local result = process:Wrap(
        module.Function,
        table.pack(module, arg1, arg2)
    )

]]

local process = {
    updateConn = nil
}
local types = require(game:GetService("ReplicatedStorage").Services.QueueService.Types)

local _processLimit = 8
local _processInterval = 1/32
local _nextProcessTime = tick()

local _processing = {}
local _processingQueue = {}

-- Connect update intervals
function process:Connect()
    process.updateConn = game:GetService("RunService").Heartbeat:Connect(function()
        if tick() < _nextProcessTime then return end
        _nextProcessTime = tick() + _processInterval
        _processQueue()
    end)
end

-- Disconnect
function process:Disconnect()
    process.updateConn:Disconnect()
end

-- Add a new DataProcess into the environment.
function process:Add(func, args)

    -- init args
    if not args then args = {} end

    -- initialize DataProcess object
    local _proc
    _proc = {
        Retries = 3,
        Status = "processing" :: types.DataProcessStatus,
        Result = Instance.new("BindableEvent"),
        Var = {},
        Connections = {}
    } :: types.DataProcess

    -- Call a function with pcall, returns packed table arguments or false.
    _proc.Function = function()
        local ret = nil
        local succ, err = pcall(function()
            ret = table.pack(func(table.unpack(args)))
        end)

        if succ then
            task.delay(1, function()
                _proc.Cleanup()
            end)
        else
            warn(err)
        end
        
        return ret, err
    end

    -- Tries to use the function, if we need to retry then we will check if we can retry, and retry
    -- Use this when calling DataProcess Function.
    _proc.Try = function()

        local retry = false
        _proc.Retries -= 1

        -- retry on limit
        if _isProcessingLimit() then
            retry = true
        end

        -- try function
        local packedArgs, err = false, "limit"
        if not retry then
            packedArgs, err = _proc.Function()
        end

        -- retry if function not successful
        if not packedArgs then
            retry = true
        end

        -- finalize retry
        if retry then

            if not _proc.Var.isRetrying then
                _proc.Var.isRetrying = true
            end

            -- destroy at 0 retries
            if _proc.Retries <= 0 then
                _proc.Result:Fire(false)
                _proc = nil
                return "destroy" -- this will cause a fake "success" to fire in processQueue and destroy the index.
            end

            -- continue retry loop
            if _proc.Connections.retry then
                _proc.Result:Fire(_proc.Result.Event:Wait())
                return false -- this will be the for the retry's use of "try"
            end

            -- initialize retry loop
            -- will keep returning :Wait() until result is reached
            _proc.Connections.retry = _proc.Result.Event:Connect(function(result)
                if result and type(result) ~= "string" then
                    _proc.Connections.retry:Disconnect()
                    return table.unpack(result) -- this will be the final result
                end
                return result -- this will be the recieved :Wait()'s from the loop.
            end)

            -- add to process queue on first retry
            table.insert(_processingQueue, _proc)

            -- start retry loop by returning a chain of :Waits()
            return _proc.Result.Event:Wait()
        end

        if _proc.Var.isRetrying then
            _proc.Result:Fire(true)
            return true
        end
        
        return table.unpack(packedArgs) -- finished!
    end

    -- Cleanup function
    _proc.Cleanup = function()
        _proc.Result:Destroy()
        for i, v in pairs(_proc.Connections) do
            v:Disconnect()
        end
        _proc = nil
    end

    return _proc
end

-- Add and Try a DataProcess.
function process:Wrap(func, args)
    local _proc = process.Add(self, func, args)
    return _proc.Try()
end

-- Handle objects in queued
function _processQueue()
    for i, v in pairs(_processingQueue) do

        -- insert to processing queue if we can
        if #_processing >= _processLimit then return end

        table.insert(_processing, "Get")
        local ind = #_processing

        -- get only success from try,
        -- results will be passed through the
        -- result.Event:Wait() loop
        local success = v.Try()
        if success then
            _processingQueue[i] = nil
            table.remove(_processing, ind)
        end
        
    end
end

-- Check if we are processing the limit
function _isProcessingLimit()
    return #_processing >= _processLimit
end

return process
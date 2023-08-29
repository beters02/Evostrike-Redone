--[[ Processing Functions for m_inputs ]]

local process = {}

-- Sanity Checks

local function getCantIgnoreWhen(keyAction)
    -- ignore when
    if keyAction.Properties.IgnoreWhen then
        for _, ignore in pairs(keyAction.Properties.IgnoreWhen) do
            if ignore() then
                return true
            end
        end
    end
    return false
end

local function getCantRepeat(keyAction)
    if keyAction.Properties.Repeats then
        if keyAction.Var.debounce > tick() then
            return true
        else
            keyAction.Var.debounce = keyAction.Properties.RepeatDelay ~= 0 and tick() + keyAction.Properties.RepeatDelay or tick()
            return false
        end
    else
        if keyAction.Var.debounce then
            return true
        else
            keyAction.Var.debounce = true
            return false
        end
    end
    return false
end

-- Processing

-- Quick set isProcessing
function process:qsip(key: string, new: boolean) self._isProcessing[key] = new end

-- Process Down or Up based on KeyDown state
function process:smartProcessKey(key, isKeyDown, keyActions)
    local func = isKeyDown and process.processKeyDown or process.processKeyUp
    return func(self, key, keyActions)
end

function process:processKeyDown(key, keyActions)
    if self._isProcessing[key] then return end

    -- add isprocessing key
    process.qsip(self, key, true)

    -- process actions
    for index, keyAction in pairs(keyActions) do
        if index == "_keyProperties" then continue end

        -- ignore on dead
        if (not self._player.Character or self._player.Character.Humanoid.Health <= 0) and keyAction.Properties.IgnoreOnDead then continue end

        -- sanity
        if getCantIgnoreWhen(keyAction) then continue end
        if getCantRepeat(keyAction) then continue end
        
        -- process function
        -- possibly will want to access this thread so 2 inputs aren't registered at the same time
        task.spawn(function()
            local args = {}
            if #keyAction.Args > 0 then args = table.unpack(keyAction.Args) end
            keyAction.Function(args)
        end)
    end

    process.qsip(self, key, nil)
end

function process:processKeyUp(key, keyActions)
    for index, keyAction in pairs(keyActions) do
        if index == "_keyProperties" then continue end
        if keyAction.Properties.Repeats or not keyAction.Var.debounce then continue end
        keyAction.Var.debounce = false

        if keyAction.KeyUpFunction then
            keyAction.KeyUpFunction()
        end
        
    end
end

return process
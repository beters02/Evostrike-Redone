-- CONFIG
local QUEUE_DELAY = 2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local NetClient = require(Framework.Module.NetClient)
local EvoMM = require(Framework.Module.EvoMMWrapper)

local Queuer = {
    IsInQueue = false,
    LastQueueTime = 0
}

-- Add a Player to the Queue. Waits for QUEUE_DELAY
function Queuer.Join()
    if tick() - Queuer.LastQueueTime < QUEUE_DELAY then
        repeat task.wait(1/60) until tick() - Queuer.LastQueueTime >= QUEUE_DELAY
    end
    local success = EvoMM:AddPlayerToQueue(game.Players.LocalPlayer, "1v1")
    if success then
        Queuer.IsInQueue = true
    end
    return success
end

-- Remove a Player from the Queue. Tries to process request as fast as possible.
function Queuer.Leave()
    Queuer.IsInQueue = false

    local tries = 3
    local success = false
    local function recurse()
        tries -= 1
        success = NetClient:MakeRequest(function()
            return EvoMM:RemovePlayerFromQueue(game.Players.LocalPlayer)
        end)
        if not success and tries > 0 then
            task.wait(0.5)
            recurse()
        end
    end

    recurse()

    if not success then
        -- warn with some error
    end
end

return Queuer
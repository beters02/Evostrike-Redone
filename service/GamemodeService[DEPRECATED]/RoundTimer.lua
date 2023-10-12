local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Types = require(script.Parent:WaitForChild("Types"))

local timer = {}
timer.__index = timer

function timer.new(length)
    local self = {} :: Types.RoundTimer
    self.Time = 0
    self.TimeLength = length
    self.TimeLeft = self.TimeLength
    self.Status = "Init"
    self.Finished = Instance.new("BindableEvent", game:GetService("ServerStorage"))
    self.TimeUpdated = Instance.new("BindableEvent", game:GetService("ServerStorage"))

    return setmetatable(self, timer)
end

function timer:Start()
    if self.Status == "Started" then warn("Timer already started!") return false end
    if self.Status == "Stopped" then warn("Cannot resume timer from a 'Stopped' state!") return false end

    self.Status = "Started"

    local lastSecStartTick = tick()
    self._connection = RunService.Heartbeat:Connect(function()
        if self.Status == "Stopped" then return end -- Be sure you disconnect your timers by calling :Stop()
        self.TimeLeft = self.TimeLength - self.Time
        if tick() - lastSecStartTick >= 1 then
            lastSecStartTick = tick()
            self.Time += 1
            self.TimeUpdated:Fire(self.Time)
        end
        if self.Time >= self.TimeLength then
            self:Stop("RoundOverTimer")
            self.Status = "Stopped"
        end
    end)
end

function timer:Stop(result)
    if not result then result = "Restart" end
    if self.Status == "Stopped" then warn("Timer already stopped!") return false end
    self.Status = "Stopped"
    self._connection:Disconnect()
    self.Finished:Fire(result)
    Debris:AddItem(self.Finished, 5)
    Debris:AddItem(self.TimeUpdated, 5)
    return true
end

function timer:Pause()
    if self.Status ~= "Started" then warn("Timer not running!") return false end
    self.Status = "Paused"
    self._connection:Disconnect()
    return true
end

return timer
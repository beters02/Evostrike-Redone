export type Timer = {
    Length: number,
    Time: number,
    TimeElapsed: number,
    Finished: BindableEvent,
    Status: "Neutral" | "Paused" | "Running",

    Start: (Timer) -> (),
    Pause: (Timer) -> (),
    Stop: (Timer) -> (),
    Destroy: (Timer) -> ()
}

local RunService = game:GetService("RunService")

local Timer = {}
Timer.__index = Timer

function Timer.new(length)
    local self = {
        Length = length,
        Time = length,
        TimeElapsed = 0,
        Status = "Neutral",
        Finished = Instance.new("BindableEvent", game.ServerStorage)
    }
    return setmetatable(self, Timer) :: Timer
end

function Timer:Start()
    assert(self.Status ~= "Running", "Timer already running.")
    self.Connection = RunService.Heartbeat:Connect(function(dt)
        if self.Time <= 0 then return end

        self.Time -= dt
        self.TimeElapsed += dt

        if self.Time <= 0 then
            self.Finished:Fire()
            task.delay(0.2, function() self:Destroy() end)
        end
    end)
end

function Timer:Stop()
    self:Destroy()
end

function Timer:Destroy()
    self.Connection:Disconnect()
    self.Finished:Destroy()
    self = nil
end

return Timer
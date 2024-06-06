--[[
    A TweenObject is an object that combines a group of tweens into one.

    All tweens will manually be destroyed upon TweenObject:Cancel()
    If you do not call :Cancel() manually, the garbage collector will handle them
]]

type TweenObjectState = "Playing" | "Paused" | "Init" | "End"

local TweenObject = {}
TweenObject.__index = TweenObject

function TweenObject.new(tweens: {Tween})
    local self = {}
    self.Tweens = {}
    self.State = "Init"

    for _, v in pairs(tweens) do
        table.insert(self.Tweens, v)
    end

    return setmetatable(self, TweenObject)
end

function TweenObject:Play()
    if self.State == "Playing" then
        return
    end

    for _, v in pairs(self.Tweens) do
        v:Play()
        v.Completed:Once(function()
            self.State = "End"
        end)
    end

    self.State = "Playing"
end

function TweenObject:PlayInOrder()
    if self.State == "Playing" then
        return
    end

    self.State = "Playing"

    for i, v in pairs(self.Tweens) do
        v:Play()
        v.Completed:Wait()
        if i >= #self.Tweens then
            self.State = "End"
        end
    end
end

function TweenObject:Pause()
    if self.State ~= "Playing" then
        return
    end

    for _, v in pairs(self.Tweens) do
        v:Pause()
    end

    self.State = "Paused"
end

function TweenObject:Cancel()
    if self.State == "End" then
        return
    end

    self.State = "End"

    for _, v in pairs(self.Tweens) do
        v:Cancel()
        v:Destroy()
    end
end

function TweenObject:Destroy()
    if self.State == "End" then
        return
    end

    self.State = "End"

    for _, v in pairs(self.Tweens) do
        v:Destroy()
    end

    self = nil
end

function TweenObject:IsPlaying()
    return self.State == "Playing"
end

return TweenObject
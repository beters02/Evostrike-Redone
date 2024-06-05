local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

CollectionService:GetInstanceAddedSignal("HealthPack"):Connect(function(instance)
    local ti = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1)
    local tween = TweenService:Create(instance:WaitForChild("Handle"), ti, {Rotation = Vector3.new(0, math.rad(360), 0)})
    tween:Play()

    local conn
    conn = instance:WaitForChild("Handle").Touched:Connect(function(p)
        if Players:GetPlayerFromCharacter(p.Parent) then
            if p.Parent.Humanoid.Health <= 0 then
                return
            end

            instance.RemoteEvent:FireServer()
            task.delay(1, function() tween:Destroy() end)
            conn:Disconnect()
        end
    end)
end)
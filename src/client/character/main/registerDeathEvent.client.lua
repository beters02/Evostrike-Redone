local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local DiedBind = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE")

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

hum.Died:Connect(function()
    local killer = char:FindFirstChild("DamageTag") and char.DamageTag.Value or false
    DiedEvent:FireServer(killer)
    DiedBind:Fire(killer)
end)
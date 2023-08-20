local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

hum.Died:Connect(function()
    DiedEvent:FireServer()
end)
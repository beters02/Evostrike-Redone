-- default died event connection
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")

DiedEvent.OnServerEvent:Connect(function(player)
    print("Worked!")
end)
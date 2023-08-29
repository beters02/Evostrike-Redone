game:GetService("Players").PlayerAdded:Connect(function(player)
    player:SetAttribute("Loaded", false)
end)

game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("playerLoadedEvent").OnServerEvent:Connect(function(player)
    player:SetAttribute("Loaded", true)
end)
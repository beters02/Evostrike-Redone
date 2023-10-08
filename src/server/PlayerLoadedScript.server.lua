game:GetService("Players").PlayerAdded:Connect(function(player)
    player:SetAttribute("Loaded", false)
    local guiContainer = Instance.new("ScreenGui")
    guiContainer.Name = "Container"
    guiContainer.ResetOnSpawn = false
    guiContainer.Parent = player:WaitForChild("PlayerGui")
end)

game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("playerLoadedEvent").OnServerEvent:Connect(function(player)
    player:SetAttribute("Loaded", true)
end)
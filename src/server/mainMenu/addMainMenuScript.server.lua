local Players = game:GetService("Players")
Players.PlayerAdded:Connect(function(player)
    -- Add Main Menu UI
    script.Parent:WaitForChild("MainMenu"):Clone().Parent = player.PlayerGui
end)
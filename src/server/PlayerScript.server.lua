game:GetService("Players").PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local hum: Humanoid = char:WaitForChild("Humanoid")
        hum.BreakJointsOnDeath = false
    end)
end)
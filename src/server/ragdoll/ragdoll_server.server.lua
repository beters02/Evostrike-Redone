local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RagdollEvents = ReplicatedStorage:WaitForChild("ragdoll"):WaitForChild("remote")

-- Connect Events

-- Make All Humanoids not BreakJointsOnDeath
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local hum: Humanoid = char:WaitForChild("Humanoid")
        hum.BreakJointsOnDeath = false
    end)
end)
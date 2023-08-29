local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RagdollEvents = ReplicatedStorage:WaitForChild("ragdoll"):WaitForChild("remote")

-- Connect Events
RagdollEvents.sharedRagdollRE.OnServerEvent:Connect(function(player, ragdoll)

end)

-- Make All Humanoids not BreakJointsOnDeath
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.spawn(function()
            for i, v in pairs(char:GetChildren()) do
                if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
                    v.CollisionGroup = "DeadCharacters"
                end
            end
        end)

        local hum: Humanoid = char:WaitForChild("Humanoid")
        hum.BreakJointsOnDeath = false
    end)
end)
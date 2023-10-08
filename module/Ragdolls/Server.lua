local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RagdollEvents = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Ragdolls"):WaitForChild("Remotes")

-- Connect Events
RagdollEvents.RemoteEvent.OnServerEvent:Connect(function()end)

-- Make All Humanoids not BreakJointsOnDeath
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local hum: Humanoid = char:WaitForChild("Humanoid")
        hum.BreakJointsOnDeath = false
        hum.Died:Once(function()
            task.spawn(function()
                for _, v in pairs(char:GetChildren()) do
                    if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
                        v.CollisionGroup = "DeadCharacters"
                    end
                end
            end)
        end)
    end)
end)
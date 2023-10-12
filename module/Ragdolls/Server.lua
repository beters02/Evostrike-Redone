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
    end)
end)

ReplicatedStorage.Modules.EvoPlayer.Events.PlayerDiedRemote.OnServerEvent:Connect(function(player)
    player.Character.HumanoidRootPart.Anchored = true
    player.Character.HumanoidRootPart:SetNetworkOwner(player)
    for _, v in pairs(player.Character:GetChildren()) do
        if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
            v.CollisionGroup = "DeadCharacters"
            v.CanCollide = true
        end
    end
end)
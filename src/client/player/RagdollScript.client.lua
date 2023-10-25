-- TAGS
-- Ragdolls_DestroyOnRemove_{PlayerName}
-- Ragdolls_DestroyOnDeath_{PlayerName}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local playerdata
local ragdoll
local util

local config = {
	ImpulseRandomValues = Vector2.new(130, 200),
	MaxFrictionTorque = 0.3,
	ElbowFrictionTorque = 1,
	KneeFrictionTorque = 1
}

playerdata = {
    stored = {},
    init = function(player)
        if not playerdata.stored[player.Name] then
            playerdata.stored[player.Name] = {
                added = player.CharacterAdded:Connect(function(character)
                    ragdoll.init(player, character)
                end),
                died = false
            }
        end
        if player.Character and not player.Character:GetAttribute("HasRagdoll") then
            ragdoll.init(player, player.Character)
        end
    end,
    connectDied = function(player, character, ragdollClone)
        if not playerdata.stored[player.Name] then
            playerdata.init(player)
        end
        if playerdata.stored[player.Name].died then
            playerdata.stored[player.Name].died:Disconnect()
            playerdata.stored[player.Name].died = nil
        end
        playerdata.stored[player.Name].died = character:WaitForChild("Humanoid").Died:Once(function()
            ragdoll.died(character, ragdollClone)
        end)
    end,
    remove = function(player)
        if playerdata.stored[player.Name] then
            for _, conn in pairs(playerdata.stored[player.Name]) do
                conn:Disconnect()
            end
        end
        playerdata.stored[player.Name] = nil
    end
}

ragdoll = {
    stored = {},

    --@summary Initialize a Player's Ragdoll and reset any past Ragdoll variables.
    init = function(player, character)
        util.transparency(character, 0)
        util.setCharacterCollision(character)
        playerdata.connectDied(player, character, ragdoll.createClone(character))
    end,

    createClone = function(character)
        local ragdollValue = character:FindFirstChild("RagdollValue")
        if ragdollValue and ragdollValue.Value then
            ragdollValue.Value:Destroy()
            ragdollValue:Destroy()
        end

        local clone = game:GetService("StarterPlayer").StarterCharacter:Clone()
        clone.Parent = ReplicatedStorage:WaitForChild("temp")
        task.wait()

        ragdollValue = Instance.new("ObjectValue")
        ragdollValue.Name = "RagdollValue"
        ragdollValue.Value = clone
        ragdollValue.Parent = character
        CollectionService:AddTag(clone, "Ragdolls_DestroyOnRemove_" .. character.Name)
        CollectionService:AddTag(ragdollValue, "Ragdolls_DestroyOnRemove_" .. character.Name)
        character:SetAttribute("HasRagdoll", true)
        return clone
    end,

    initDeathParts = function(ragdollClone)
        local charHum = ragdollClone:WaitForChild("Humanoid")
        ragdollClone.PrimaryPart = ragdollClone:WaitForChild("UpperTorso")
        charHum:Destroy()
        ragdollClone.HumanoidRootPart:Destroy()

        for _, v in pairs(ragdollClone:GetDescendants()) do
            if v:IsA("Motor6D") then
                if not string.match(v.Name, "Ankle") and not string.match(v.Name, "Wrist") then
                    local part0 = v.Part0
                    local joint_name = v.Name
                    local attachment0 = v.Parent:FindFirstChild(joint_name.."Attachment") or v.Parent:FindFirstChild(joint_name.."RigAttachment")
                    local attachment1 = part0:FindFirstChild(joint_name.."Attachment") or part0:FindFirstChild(joint_name.."RigAttachment")
                    if attachment0 and attachment1 then
                        local socket = Instance.new("BallSocketConstraint", v.Parent)
                        socket.LimitsEnabled = true
                        socket.TwistLimitsEnabled = true
                        socket.MaxFrictionTorque = (joint_name == "Knee" and config.KneeFrictionTorque) or (joint_name == "Elbow" and config.ElbowFrictionTorque) or config.MaxFrictionTorque
                        socket.Attachment0, socket.Attachment1 = attachment0, attachment1
                        v:Destroy()
                    end
                end
            end
        end
    end,

    replaceCharacter = function(character, ragdollClone)
        if not character.PrimaryPart then return end
        character.PrimaryPart.Anchored = true
        ragdollClone:SetPrimaryPartCFrame(character.PrimaryPart.CFrame)
        util.transparency(character, 1)
        ragdollClone.Parent = character.Parent
        ragdollClone.PrimaryPart.Velocity = character.PrimaryPart.Velocity
        character:SetPrimaryPartCFrame(ragdollClone.PrimaryPart.CFrame + Vector3.new(0,2,0))
    end,

    impulse = function(character, ragdollClone)
        local bulletRagdollNorm = -(character:GetAttribute("bulletRagdollKillDir") or Vector3.new(math.random(1,10),math.random(1,10),math.random(1,10)).Unit)
        local impulseModifier = character:GetAttribute("impulseModifier") or 1

        if bulletRagdollNorm then
            local bulletRagdollPart
            local bulletRagdollPartName = character:GetAttribute("lastHitPart")

            if not bulletRagdollPartName then bulletRagdollPart = ragdollClone.Head else
                bulletRagdollPart = ragdollClone:FindFirstChild(bulletRagdollPartName)
                if not bulletRagdollPart then bulletRagdollPart = ragdollClone.Head end
            end

            local randomVec3 = Vector3.one * impulseModifier
            local impulseAmount = (Vector3.new(bulletRagdollNorm.X * randomVec3.X, 0, bulletRagdollNorm.Z * randomVec3.Z) * math.random(config.ImpulseRandomValues.X, config.ImpulseRandomValues.Y))
            bulletRagdollPart:ApplyImpulse(impulseAmount)
        end
    end,

    died = function(character, ragdollClone)
        pcall(function()
            character.PrimaryPart.Anchored = true
            character.Head.Anchored = true
        end)
        util.setDeadCharacterCollision(character)
        ragdoll.initDeathParts(ragdollClone)
        
        ragdoll.replaceCharacter(character, ragdollClone)
        util.setRagdollCollision(ragdoll)
        
        ragdoll.impulse(character, ragdollClone)
    
        Debris:AddItem(ragdoll, 6)
    end
}

util = {
    transparency = function(character, t)
        for _, v in pairs(character:GetDescendants()) do
            if v.Name ~= "HumanoidRootPart" and (v:IsA("Part") or v:IsA("MeshPart") or v:IsA("Texture")) then
                v.Transparency = t
            end
        end
    end,
    setCharacterCollision = function(character)
        for _, v in pairs(character:GetChildren()) do
            if not v:IsA("Part") and not v:IsA("MeshPart") then continue end
            v.Anchored = false
            v.CollisionGroup = "Players"
            if v.Name == "LeftFoot" or v.Name == "RightFoot" then
                v.CollisionGroup = "PlayerFeet"
            end
        end
    end,
    setDeadCharacterCollision = function(character)
        for _, v in pairs(character:GetChildren()) do
            if not v:IsA("Part") and not v:IsA("MeshPart") then continue end
            v.Anchored = true
            v.CollisionGroup = "DeadCharacters"
        end
    end,
    setRagdollCollision = function(ragdoll)
        for _, v in pairs(ragdoll:GetChildren()) do
            if not v:IsA("Part") and not v:IsA("MeshPart") then continue end
            v.CollisionGroup = "Ragdolls"
        end
    end
}

-- Connections
Players.PlayerAdded:Connect(function(player)
    playerdata.init(player)
end)

Players.PlayerRemoving:Connect(function(player)
    playerdata.remove(player)
end)

-- Init Self & Current Players
playerdata.init(Players.LocalPlayer)
for _, v in pairs(Players:GetPlayers()) do
    playerdata.init(v)
end
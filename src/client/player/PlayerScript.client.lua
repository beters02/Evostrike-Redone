local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EvoPlayerEvents = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EvoPlayer"):WaitForChild("Events")
local SelfDiedEvent = EvoPlayerEvents:WaitForChild("PlayerDiedBindable")
local PlayerDiedEvent = EvoPlayerEvents:WaitForChild("PlayerDiedRemote")

local Ragdolls = {
    Stored = {},
    config = {
        ImpulseRandomValues = Vector2.new(130, 200),
        MaxFrictionTorque = 0.3,
        ElbowFrictionTorque = 1,
        KneeFrictionTorque = 1,
        RagdollDecayLength = 6,
    }
}

-- | Main |
function main()
    playerAdded(game.Players.LocalPlayer)
    for _, v in pairs(Players:GetPlayers()) do
        playerAdded(v)
    end
    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)
end

function update(dt)

end

function playerAdded(player)
    Ragdolls.initPlayer(player)
end

function playerRemoving(player)
    Ragdolls.removePlayer(player)
end

-- | Ragdolls |

function Ragdolls.initPlayer(player)
    print('initting ' .. player.Name)
    if not Ragdolls.Stored[player.Name] then
        local ragdollData = {Player = player, Connections = {}, CharacterAlive = false}
        ragdollData.Connections.CharacterAdded = player.CharacterAdded:Connect(function(char)
            print('Character Added ' .. player.Name)
            Ragdolls.characterAdded(player, char)
        end)
        Ragdolls.Stored[player.Name] = ragdollData
    end

    if player.Character and not Ragdolls.Stored[player.Name].CharacterAlive then
        Ragdolls.characterAdded(player, player.Character)
    end
end

function Ragdolls.getPlayer(player)
    return Ragdolls.Stored[player.Name]
end

function Ragdolls.removePlayer(player)
    if Ragdolls.Stored[player.Name] then
        for _, v in pairs(Ragdolls.Stored[player.Name].Connections) do
            v:Disconnect()
        end
        for _, v in pairs(CollectionService:GetTagged("Ragdolls_DestroyOnRemove_" .. player.Name)) do
            v:Destroy()
        end
        Ragdolls.Stored[player.Name] = nil
    end
end

function Ragdolls.characterAdded(player, char)
    Ragdolls.initCharacterSpawn(char)

    local clone = Ragdolls.createRagdoll(char)
    local ragdollData = Ragdolls.getPlayer(player)

    if player == game.Players.LocalPlayer then
        ragdollData.Connections.Died = SelfDiedEvent.Event:Once(function()
            print('died!')
            Ragdolls.characterDied(player, char, clone)
        end)
    else
        ragdollData.Connections.Died = PlayerDiedEvent.OnClientEvent:Connect(function(diedPlr)
            if diedPlr == player then
                print('died!')
                Ragdolls.characterDied(player, char, clone)
                ragdollData.Connections.Died:Disconnect()
            end
        end)
    end

    ragdollData.CharacterAlive = true
    Ragdolls.Stored[player.Name] = ragdollData
end

function Ragdolls.characterDied(player, character, ragdollClone)
    Ragdolls.ragdollCharacter(character, ragdollClone)
    Ragdolls.Stored[player.Name].CharacterAlive = false
end

function Ragdolls.initCharacterSpawn(char)
    for _, v in pairs(char:GetDescendants()) do
        if v.Name == "HumanoidRootPart" then
            v.Anchored = false
            v.CollisionGroup = "Players"
            continue
        elseif v:IsA("Texture") then
            v.Transparency = 0
            continue
        elseif not v:IsA("Part") and not v:IsA("MeshPart") and not v:IsA("BasePart") then
            continue
        end

        v.Transparency = 0
        v.Anchored = false
        v.CollisionGroup = "Players"
        if v.Name == "LeftFoot" or v.Name == "RightFoot" then
            v.CollisionGroup = "PlayerFeet"
        end
    end
end

function Ragdolls.initCharacterDead(char)
    for _, v in pairs(char:GetDescendants()) do
        if v.Name == "HumanoidRootPart" then
            v.Anchored = true
            v.CollisionGroup = "DeadCharacters"
            v.CanCollide = true
            continue
        elseif v:IsA("Texture") then
            v.Transparency = 1
            continue
        elseif not v:IsA("Part") and not v:IsA("MeshPart") and not v:IsA("BasePart") then
            continue
        end

        v.Transparency = 1
        v.Anchored = true
        v.CollisionGroup = "DeadCharacters"
        v.CanCollide = true
    end
end

function Ragdolls.createRagdoll(char)
    local ragdollValue = char:FindFirstChild("RagdollValue")
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
    ragdollValue.Parent = char
    CollectionService:AddTag(clone, "Ragdolls_DestroyOnRemove_" .. char.Name)
    CollectionService:AddTag(ragdollValue, "Ragdolls_DestroyOnRemove_" .. char.Name)
    char:SetAttribute("HasRagdoll", true)

    -- prepare ragdoll CanCollide & constraints
    for _, v in pairs(clone:GetDescendants()) do
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
                    socket.MaxFrictionTorque = (joint_name == "Knee" and Ragdolls.config.KneeFrictionTorque) or (joint_name == "Elbow" and Ragdolls.config.ElbowFrictionTorque) or Ragdolls.config.MaxFrictionTorque
                    socket.Attachment0, socket.Attachment1 = attachment0, attachment1
                    v:Destroy()
                end
            end
        elseif v:IsA("Part") or v:IsA("MeshPart") then
            v.CanCollide = true
            v.CollisionGroup = "Ragdolls"
        end
    end

    return clone
end

function Ragdolls.ragdollCharacter(character, ragdollClone)
    pcall(function()
        character.PrimaryPart.Anchored = true
        character.Head.Anchored = true
    end)

    Ragdolls.initCharacterDead(character)

    local charHum = ragdollClone:WaitForChild("Humanoid")
    ragdollClone.PrimaryPart = ragdollClone:WaitForChild("UpperTorso")
    charHum:Destroy()
    ragdollClone.HumanoidRootPart:Destroy()

    -- replace char with ragdoll
    character.PrimaryPart.Anchored = true
    ragdollClone:SetPrimaryPartCFrame(character.PrimaryPart.CFrame)
    Ragdolls.transparency(character, 1)
    ragdollClone.Parent = character.Parent
    ragdollClone.PrimaryPart.Velocity = character.PrimaryPart.Velocity
    character:SetPrimaryPartCFrame(ragdollClone.PrimaryPart.CFrame + Vector3.new(0,2,0))
    
    -- impulse ragdoll
    Ragdolls.impulse(character, ragdollClone)
    game:GetService("Debris"):AddItem(ragdollClone, Ragdolls.config.RagdollDecayLength)
end

function Ragdolls.impulse(character, ragdollClone)
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
        local impulseAmount = (Vector3.new(bulletRagdollNorm.X * randomVec3.X, 0, bulletRagdollNorm.Z * randomVec3.Z) * math.random(Ragdolls.config.ImpulseRandomValues.X, Ragdolls.config.ImpulseRandomValues.Y))
        bulletRagdollPart:ApplyImpulse(impulseAmount)
    end
end

function Ragdolls.transparency(character, t)
    for _, v in pairs(character:GetDescendants()) do
        if v.Name ~= "HumanoidRootPart" and (v:IsA("Part") or v:IsA("MeshPart") or v:IsA("Texture")) then
            v.Transparency = t
        end
    end
end

-- | TorsoToMouse |


-- | Script Start |
main()
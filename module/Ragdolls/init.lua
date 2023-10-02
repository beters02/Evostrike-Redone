local RunService = game:GetService("RunService")
if RunService:IsServer() then return require(script:WaitForChild("Server")) end

local Shared = {}

local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

--[[
    Initializes Death Connections for All current Players
    and player's added for the LocalPlayer.
]]

--[[
	Configuration
]]

local config = {
	ImpulseRandomValues = Vector2.new(130, 200)
}

--

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RagdollRE = script:WaitForChild("Remotes").RemoteEvent
local PlayerDied = Framework.Module.EvoPlayer.Events.PlayerDiedRemote

local playerConns = {}
local nonPlayerDolls = {}

-- Init NonPlayer Ragdolls (Every time a new bot is spawned, create ragdoll clone)

function NonPlayerInitRagdoll(character)
    local doll, hum, conn = CreateRagdoll(character)
	nonPlayerDolls[character.Name] = doll
	conn:Disconnect()
	conn = RunService.RenderStepped:Connect(function()
		if hum then
			local lastRegistered = hum.Parent:GetAttribute("LastRegisteredHealth")
			if (lastRegistered and lastRegistered <= 0) or not hum or hum.Health <= 0 then
				DiedRagdoll(character, doll)
				nonPlayerDolls[character.Name] = nil
				conn:Disconnect()
			end
			return
		end
		
		DiedRagdoll(character, doll)
		nonPlayerDolls[character.Name] = nil
		conn:Disconnect()
	end)
end

-- Init Player Ragdolls (Once per player, Connect Connections for CharacterAdded)

function PlayerInitRagdoll(plr)
    -- connect character added
    if playerConns[plr.Name] then return end
    playerConns[plr.Name] = plr.CharacterAdded:Connect(function(character)
        CreateRagdoll(character)
		resetCharCollision(character)
    end)
end

-- Shared Functions

function DiedRagdoll(character, ragdoll)
	setCharCollision(character)

    initRagdollParts(ragdoll)
    replaceCharacterWithRagdoll(character, ragdoll)
	setRagCollision(ragdoll)

	task.wait()
	impulseRagdoll(ragdoll, character)

	Debris:AddItem(ragdoll, 6)
end

function CreateRagdoll(character)
    local ragdoll = createRagdollClone(character)

    -- connect died event
    local hum = character:WaitForChild("Humanoid")
    local conn
	conn = PlayerDied.OnClientEvent:Connect(function(player)
		if player.Name == character.Name then
			DiedRagdoll(character, ragdoll)
			conn:Disconnect()
		end
    end)
	return ragdoll, hum, conn
end

-- Connection Functions

function SharedRE(action, ...)
    if action == "NonPlayerInitRagdoll" then
        local character = ...
        NonPlayerInitRagdoll(character)
    end
end

-- Utility Functions

function createRagdollClone(character)
    local clone = game:GetService("StarterPlayer").StarterCharacter:Clone()
    clone.Parent = ReplicatedStorage:WaitForChild("temp")
	task.wait()

	local ragdollValue = Instance.new("ObjectValue")
	ragdollValue.Name = "RagdollValue"
	ragdollValue.Value = clone
	ragdollValue.Parent = character

    return clone
end

function initRagdollParts(char)

	local charHum = char:WaitForChild("Humanoid")
	char.PrimaryPart = char.UpperTorso
	charHum:Destroy()
	char.HumanoidRootPart:Destroy()
	if char:FindFirstChild("EnemyHighlight") then
		char.EnemyHighlight:Destroy()
	end

	for i, v in pairs(char:GetDescendants()) do
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
					socket.Attachment0, socket.Attachment1 = attachment0, attachment1
					v:Destroy()
				end	
			end
		end
	end

end

function setRagCollision(char)
	for i, v in pairs(char:GetChildren()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v.CollisionGroup = "Ragdolls"
			v.CanCollide = true
			if v:FindFirstChild(v.Name .. "_HB") then
				v[v.Name.."_HB"].CollisionGroup = "Ragdolls"
				v[v.Name.."_HB"].CanCollide = true
			end
		end
	end
end

function setCharCollision(char)
	for i, v in pairs(char:GetChildren()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v.CanCollide = true
			v.CollisionGroup = "DeadCharacters"
			if v:FindFirstChild(v.Name .. "_HB") then
				v[v.Name.."_HB"].CanCollide = true
				v[v.Name.."_HB"].CollisionGroup = "DeadCharacters"
			end
		end
	end
end

function resetCharCollision(char)
	for i, v in pairs(char:GetChildren()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v.CanCollide = true
			if string.match(v.Name, "Foot") then
				v.CollisionGroup = "PlayerFeet"
			else
				v.CollisionGroup = "Players"
			end
			if v:FindFirstChild(v.Name .. "_HB") then
				v[v.Name.."_HB"].CanCollide = true
				v[v.Name.."_HB"].CollisionGroup = "Players"
			end
		end
	end
end

function transparency(char, t)
    for i, v in pairs(char:GetDescendants()) do
        if (not v:IsA("Part") and not v:IsA("MeshPart")) or v.Name == "HumanoidRootPart" then continue end
        v.Transparency = t
    end
end

function replaceCharacterWithRagdoll(char, clone)
	local highlight = char:FindFirstChild("EnemyHighlight")
	if highlight then highlight.Parent = clone end
	clone:SetPrimaryPartCFrame(char.PrimaryPart.CFrame)
	transparency(char, 1)
	clone.Parent = char.Parent
	clone.PrimaryPart.Velocity = char.PrimaryPart.Velocity
end

function impulseRagdoll(char, oldChar)
	local bulletRagdollNorm = -(oldChar:GetAttribute("bulletRagdollKillDir") or Vector3.new(math.random(1,10),math.random(1,10),math.random(1,10)).Unit)
	local impulseModifier = oldChar:GetAttribute("impulseModifier") or 1

	if bulletRagdollNorm then
		local bulletRagdollPart
		local bulletRagdollPartName = oldChar:GetAttribute("lastHitPart")

		if not bulletRagdollPartName then bulletRagdollPart = char.Head else
			if string.match(bulletRagdollPartName, "HB") then
				bulletRagdollPart = char:FindFirstChild(string.gsub(bulletRagdollPartName, "_HB", ""))
			else
				bulletRagdollPart = char:FindFirstChild(bulletRagdollPartName)
			end
			if not bulletRagdollPart then bulletRagdollPart = char.Head end
		end

		task.spawn(function()
			local randomVec3 = Vector3.one * impulseModifier
			local impulseAmount = (Vector3.new(bulletRagdollNorm.X * randomVec3.X, 0, bulletRagdollNorm.Z * randomVec3.Z) * math.random(config.ImpulseRandomValues.X, config.ImpulseRandomValues.Y))
			bulletRagdollPart:ApplyImpulse(impulseAmount)
		end)

	end
end

-- [[ Run ]]

local tplayers = Players:GetPlayers()
if #tplayers > 0 then for _, v in pairs(tplayers) do PlayerInitRagdoll(v) end end -- Initialize all current players

-- connections
Players.PlayerAdded:Connect(PlayerInitRagdoll) -- Initialize new players
RagdollRE.OnClientEvent:Connect(SharedRE)

return Shared
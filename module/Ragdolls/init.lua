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
	ImpulseRandomValues = Vector2.new(130, 200),
	MaxFrictionTorque = 0.3,
	ElbowFrictionTorque = 1,
	KneeFrictionTorque = 1
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

type rodTable = {
	lRod: RodConstraint,
	rRod: RodConstraint,
	ltop: Attachment,
	rtop: Attachment,
	lbottom: Attachment,
	rbottom:Attachment
}
local rodTable = {}

--@summary Generate a new rodTable
function rodTable.new()
	local self = {
		lRod = Instance.new("RodConstraint"),
		rRod = Instance.new("RodConstraint"),
		ltop = Instance.new("Attachment"),
		rtop = Instance.new("Attachment"),
		lbottom = Instance.new("Attachment"),
		rbottom = Instance.new("Attachment")
	}
	self.lRod.Visible = true
	self.rRod.Visible = true
	return self
end

function initPartTopRodPos(part, pos, size, rods)
	rods.lRod.Parent = part
	rods.rRod.Parent = part
	rods.ltop.Parent = part
	rods.rtop.Parent = part
	rods.rtop.CFrame = CFrame.new(Vector3.new(pos.X - (size.X/2), pos.Y + (size.Y/2), pos.Z)) -- move rrod attatchment to the top right corner
	rods.ltop.CFrame = CFrame.new(Vector3.new(pos.X + (size.X/2), pos.Y + (size.Y/2), pos.Z)) -- move lrod attatchment to the top left corner
end

function initPartBottomRodPos(part, pos, size, rods)
	rods.lbottom.Parent = part
	rods.rbottom.Parent = part
	rods.rbottom.CFrame = CFrame.new(Vector3.new(pos.X - (size.X/2), pos.Y - (size.Y/2), pos.Z)) -- move rrod attatchment to the bottom right corner
	rods.lbottom.CFrame = CFrame.new(Vector3.new(pos.X + (size.X/2), pos.Y - (size.Y/2), pos.Z)) -- move lrod attatchment to the bottom left corner
end

function finalizeRods(lRods: rodTable, rRods: rodTable)
	for _, rods in ipairs({lRods, rRods}) do
		rods.lRod.Attachment0 = rods.ltop
		rods.lRod.Attachment1 = rods.lbottom
		rods.rRod.Attachment0 = rods.rtop
		rods.rRod.Attachment1 = rods.rbottom
	end
end

function initRagdollParts(char)
	local charHum = char.Humanoid
	char.PrimaryPart = char.UpperTorso
	charHum:Destroy()
	char.HumanoidRootPart:Destroy()
	--[[if char:FindFirstChild("EnemyHighlight") then
		char.EnemyHighlight:Destroy()
	end]]

	--local lRods = rodTable.new()
	--local rRods = rodTable.new()

	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("Motor6D") then
			if not string.match(v.Name, "Ankle") and not string.match(v.Name, "Wrist") then

				local part0 = v.Part0
				local joint_name = v.Name
				local attachment0 = v.Parent:FindFirstChild(joint_name.."Attachment") or v.Parent:FindFirstChild(joint_name.."RigAttachment")
				local attachment1 = part0:FindFirstChild(joint_name.."Attachment") or part0:FindFirstChild(joint_name.."RigAttachment")
				--[[local _pos = part0.CFrame.Position
				local _size = part0.Size

				if v.Parent.Name == "RightUpperArm" then
					initPartTopRodPos(v.Parent, _pos, _size, rRods)
				elseif v.Parent.Name == "LeftUpperArm" then
					initPartTopRodPos(v.Parent, _pos, _size, lRods)
				elseif v.Parent.Name == "RightLowerArm" then
					initPartBottomRodPos(v.Parent, _pos, _size, rRods)
				elseif v.Parent.Name == "LeftLowerArm" then
					initPartBottomRodPos(v.Parent, _pos, _size, lRods)
				end]]

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

		--finalizeRods(lRods, rRods)
	end
end

function setRagCollision(char)
	for _, v in pairs(char:GetChildren()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v.CollisionGroup = "Ragdolls"
			v.CanCollide = true
		end
	end
end

function setCharCollision(char)
	for _, v in pairs(char:GetChildren()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v.CanCollide = true
			v.CollisionGroup = "DeadCharacters"
		end
	end
end

function resetCharCollision(char)
	for _, v in pairs(char:GetChildren()) do
		if v:IsA("Part") or v:IsA("MeshPart") then
			v.CanCollide = true
			if v.Name == "LeftFoot" or v.Name == "RightFoot" then
				v.CollisionGroup = "PlayerFeet"
			else
				v.CollisionGroup = "Players"
			end
		end
	end
end

function transparency(char, t)
    for _, v in pairs(char:GetDescendants()) do
        if (not v:IsA("Part") and not v:IsA("MeshPart")) or v.Name == "HumanoidRootPart" then continue end
        v.Transparency = t
    end
end

function replaceCharacterWithRagdoll(char, clone)
	--local highlight = char:FindFirstChild("EnemyHighlight")
	--if highlight then highlight.Parent = clone end
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
			bulletRagdollPart = char:FindFirstChild(bulletRagdollPartName)
			if not bulletRagdollPart then bulletRagdollPart = char.Head end
		end

		local randomVec3 = Vector3.one * impulseModifier
		local impulseAmount = (Vector3.new(bulletRagdollNorm.X * randomVec3.X, 0, bulletRagdollNorm.Z * randomVec3.Z) * math.random(config.ImpulseRandomValues.X, config.ImpulseRandomValues.Y))
		bulletRagdollPart:ApplyImpulse(impulseAmount)
	end
end

-- [[ Run ]]

local tplayers = Players:GetPlayers()
if #tplayers > 0 then for _, v in pairs(tplayers) do PlayerInitRagdoll(v) end end -- Initialize all current players

-- connections
Players.PlayerAdded:Connect(PlayerInitRagdoll) -- Initialize new players
RagdollRE.OnClientEvent:Connect(SharedRE)

return Shared
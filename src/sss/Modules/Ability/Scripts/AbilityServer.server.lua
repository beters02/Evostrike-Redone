local abilityName = string.gsub(script.Parent.Parent.Name, "AbilityFolder_", "")
local abilityOptions = require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("Ability").Class[abilityName])
local abilityRemoteEvent = script.Parent.Parent.Remotes.AbilityRemoteEvent
local abilityRemoteFunction = script.Parent.Parent.Remotes.AbilityRemoteFunction
local abilityObjects = game:GetService("ReplicatedStorage"):WaitForChild("Objects"):WaitForChild("Ability"):WaitForChild(abilityName)
local serverStoredVar = {uses = abilityOptions.uses, cooldown = false}
local char = script.Parent.Parent.Parent
local player = game:GetService("Players"):GetPlayerFromCharacter(char)

--[[
	Base Functions
]]

local Functions = {}
local timerTypeKeys = {Cooldown = abilityOptions.cooldownLength}

Functions.Timer = function(timerType)
	local endTime = tick()
	local length = timerTypeKeys[timerType]
	if not length then error("Could not find timer " .. tostring(timerType)) end
	endTime += length
	repeat task.wait() until tick() >= endTime
	abilityRemoteEvent:FireClient(player, "CooldownFinished")
	print('server cooldown finisehd')
	return true
end

Functions.CanUse = function()
	if not serverStoredVar.cooldown then
		if serverStoredVar.uses <= 0 then
			return false, "USES MISMATCH"
		end
		serverStoredVar.uses -= 1
		task.spawn(function()
			Functions.Timer("Cooldown")
		end)
		return serverStoredVar.uses
	end
    
    return false, "COOLDOWN MISMATCH"
end

--[[
	Grenades
]]

local FastCast = require(game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Libraries"):WaitForChild("FastCastRedux"))
local caster, casbeh
if abilityOptions.isGrenade then
	caster = FastCast.new()
	casbeh = FastCast.newBehavior()
	casbeh.RaycastParams = RaycastParams.new()
	casbeh.RaycastParams.CollisionGroup = "Bullets"
	casbeh.RaycastParams.FilterDescendantsInstances = {char}
	casbeh.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	casbeh.MaxDistance = 500
	casbeh.Acceleration = Vector3.new(0, -workspace.Gravity * abilityOptions.gravityModifier, 0)

	casbeh.CosmeticBulletContainer = workspace.Temp
	casbeh.CosmeticBulletTemplate = abilityObjects.Models.Grenade
end

local function GrenadeOnLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
	if bullet then 
		local bulletLength = bullet.Size.Z/2
		local offset = CFrame.new(0, 0, -(length - bulletLength))
		bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
	end
end

Functions.ThrowGrenade = function(mouseHit: Vector3)
	local thrower = player
	if not abilityOptions.isGrenade or not mouseHit or not thrower then return false end
	if not Functions.CanUse() then return false end
	
	local startLv = player.Character.HumanoidRootPart.CFrame.LookVector
	local origin = player.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, 1, 0)
	local direction = (mouseHit.Position - origin).Unit
	local animated = false
   
	task.spawn(function()
		caster:Fire(origin, direction, direction * abilityOptions.speed, casbeh)
		local conns = {}
		table.insert(conns, caster.LengthChanged:Connect(GrenadeOnLengthChanged))
		table.insert(conns, caster.RayHit:Connect(abilityOptions.RayHit))
		table.insert(conns, caster.CastTerminating:Connect(function()
			for i, v in pairs(conns) do
				v:Disconnect()
			end
		end))
	end)

	return true
end

--[[
	Connections
]]

abilityRemoteFunction.OnServerInvoke = function(player, action, ...)
    if not Functions[action] then return else return Functions[action](...) end
end
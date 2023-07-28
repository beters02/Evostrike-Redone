local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Modules = game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Modules")
local Libraries = game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Libraries")
local WeaponFunctions = require(Libraries.WeaponFunctions)

local tool = script.Parent
local serverModel = tool.ServerModel
local weaponName = string.gsub(tool.Name, "Tool_", "")
local weaponRemoteFunction = tool:WaitForChild("WeaponRemoteFunction")
local weaponRemoteEvent = tool:WaitForChild("WeaponRemoteEvent")
local weaponFolder = game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("Weapon")
local weaponOptions = require(weaponFolder:WaitForChild("Options")[weaponName])

local serverStoredVar = {lastFireTime = tick(), nextFireTime = tick(), ammo = {magazine = weaponOptions.ammo.magazine, total = weaponOptions.ammo.total, lastYAcc = 0, accuracy = Vector2.zero}}
serverStoredVar.vectorOffset = weaponOptions.fireVectorCameraOffset

local player = tool:WaitForChild("PlayerObject").Value

--[[
	Remote Event Functions
]]

local timerTypeKeys = {Equip = weaponOptions.equipLength, Fire = weaponOptions.fireRate, Reload = weaponOptions.reloadLength}
local function Timer(timerType)
	local endTime = tick()
	local length = timerTypeKeys[timerType]
	if not length then error("Could not find timer " .. tostring(timerType)) end
	endTime += length
	repeat task.wait() until tick() >= endTime
	return true
end

--[[
	Hit Registration
]]

local AccuracyCalculator = require(Modules.AccuracyCalculator).init(player, weaponOptions)
local CalculateAccuracy = AccuracyCalculator.Calculate

function GetAccuracy(recoilVector3, currentBullet, speed)
	local acc
	acc, serverStoredVar = CalculateAccuracy(currentBullet, recoilVector3, serverStoredVar, speed)
	serverStoredVar.accuracy = acc
	return acc
end

--[[
	Weapon Functions
]]

local char = player.Character
--[[
local ikRight = Instance.new("IKControl")
ikRight.ChainRoot = char.RightUpperArm
ikRight.EndEffector = char.RightHand
ikRight.Parent = char:FindFirstChildOfClass("Humanoid")
ikRight.Type = Enum.IKControlType.Transform

local ikLeft = Instance.new("IKControl")
ikLeft.ChainRoot = char.LeftUpperArm
ikLeft.EndEffector = char.LeftHand
ikLeft.Parent = char:FindFirstChildOfClass("Humanoid")
ikLeft.Type = Enum.IKControlType.Transform

local ikRightNew = Instance.new("IKControl")
	ikRightNew.ChainRoot = serverModel.GunComponents.WeaponHandle.PlaceRightHand
	ikRightNew.EndEffector = serverModel.GunComponents.WeaponHandle.PlaceRightHand
	ikRightNew.Target = char.RightHand
	ikRightNew.Type = Enum.IKControlType.Transform
	ikRightNew.Parent = char:FindFirstChildOfClass("Humanoid")]]

function Equip()
	task.wait()
	--ikRight.Target = serverModel.GunComponents.WeaponHandle.PlaceRightHand
	--ikLeft.Target = serverModel.GunComponents.WeaponHandle.PlaceLeftHand

	local weaponHandle = serverModel.GunComponents.WeaponHandle

	local grip = Instance.new("Motor6D")
	grip.Parent = char.RightHand
	grip.Part0 = char.RightHand
	grip.Part1 = weaponHandle

	grip.C0 = CFrame.new(Vector3.zero) * CFrame.fromEulerAnglesXYZ(0.18523180484771729, 1.4023197889328003, -1.4882946014404297)

	--player.Character.HumanoidRootPart.WeaponGrip.Part1 =  weaponHandle
end

function Unequip()
	player.Character.HumanoidRootPart.WeaponGrip.Part1 = nil
end

function Fire(finalRay, currentBullet, recoilVector3) -- Returns BulletHole
	local diff = serverStoredVar.nextFireTime - tick()
	if diff > 0 then
		--print(tostring(diff) .. " TIME UNTIL NEXT ALLOWED FIRE")
		if diff > 0.01899 then
			print(tostring(diff) .. " TIME UNTIL NEXT ALLOWED FIRE")
			return
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, workspace.Temp}
	params.CollisionGroup = "Bullets"

	local result = workspace:Raycast(finalRay.Origin, finalRay.Direction * 100, params)

	serverStoredVar.ammo.magazine -= 1
	serverStoredVar.nextFireTime = tick() + weaponOptions.fireRate

	WeaponFunctions.RegisterShot(player, weaponOptions, result, finalRay.Origin)
end

function Reload()
	if serverStoredVar.ammo.total <= 0 then return end
	local newMag
	local defMag = weaponOptions.ammo.magazine
	task.spawn(function()
		if serverStoredVar.ammo.total >= defMag then
			newMag = defMag
			serverStoredVar.ammo.total -= defMag - serverStoredVar.ammo.magazine
		else
			newMag = serverStoredVar.ammo.total
			serverStoredVar.ammo.total = 0
		end
		serverStoredVar.ammo.magazine = newMag
	end)
	Timer("Reload")
	return newMag, serverStoredVar.ammo.total
end

--[[
	Connections
]]

local actions = {Timer = Timer, Fire = Fire, Reload = Reload, GetAccuracy = GetAccuracy}
weaponRemoteFunction.OnServerInvoke = function(plr, action, ...)
	return actions[action](...)
end

weaponRemoteEvent.OnServerEvent:Connect(function(plr, action, ...)
	actions[action](...)
end)

tool.Equipped:Connect(Equip)
tool.Unequipped:Connect(Unequip)
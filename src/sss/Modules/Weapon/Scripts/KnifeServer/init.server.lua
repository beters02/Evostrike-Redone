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
	Weapon Functions
]]

local char = player.Character

function Equip()
	task.wait()

	local weaponHandle = serverModel.GunComponents.WeaponHandle

	local grip = Instance.new("Motor6D")
	grip.Name = "RightGrip"
	grip.Parent = char.RightHand
	grip.Part0 = char.RightHand
	grip.Part1 = weaponHandle

	--grip.C0 = CFrame.new(Vector3.zero) * CFrame.fromEulerAnglesXYZ(0.18523180484771729, 1.4023197889328003, -1.4882946014404297)
end

function Unequip()
	player.Character.HumanoidRootPart.WeaponGrip.Part1 = nil
end

--[[
	Connections
]]

local actions = {Timer = Timer}
weaponRemoteFunction.OnServerInvoke = function(plr, action, ...)
	return actions[action](...)
end

weaponRemoteEvent.OnServerEvent:Connect(function(plr, action, ...)
	actions[action](...)
end)

tool.Equipped:Connect(Equip)
tool.Unequipped:Connect(Unequip)
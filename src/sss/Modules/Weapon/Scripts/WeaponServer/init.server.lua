local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Framework = require(ReplicatedStorage.Framework)
local Scripts = Framework.ReplicatedStorage.Scripts
local Modules = Framework.ReplicatedStorage.Modules
local Libraries = Framework.ReplicatedStorage.Libraries
local WeaponFunctions = require(Libraries.WeaponFunctions)
local Signal = require(Modules.Signal)

--local PlayerDamagedEvent = Framework.ReplicatedStorage.Remotes.PlayerDamaged :: BindableEvent

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

function GetAccuracyVector(currentBullet)
	return AccuracyCalculator.GetMovementInaccuracyVector2((weaponOptions.accuracy.firstBullet and currentBullet == 1) or false)
end

function RegisterShot(rayInformation, pos, origin, dir, shotRegisteredTime)
	-- create a fake result to give to server
	local fr = {Instance = rayInformation.instance, Position = pos, Normal = rayInformation.normal, Distance = rayInformation.distance, Material = rayInformation.material}
	-- register shot function
	WeaponFunctions.RegisterShot(player, weaponOptions, fr, origin, dir, shotRegisteredTime)
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

local shotServerReRegistration = false
function Fire(currentBullet, clientAccuracyVector, rayInformation, shotRegisteredTime, isFinal)

	if not isFinal then
		-- check client->server timer diff
		local diff = serverStoredVar.nextFireTime - tick()
		if diff > 0 then
			if diff > 0.01899 then
				print(tostring(diff) .. " TIME UNTIL NEXT ALLOWED FIRE")
				return
			end
		end

		-- update ammo
		serverStoredVar.ammo.magazine -= 1
		serverStoredVar.nextFireTime = tick() + weaponOptions.fireRate
	end

	local cb = currentBullet
	local pos = rayInformation.position
	local origin = rayInformation.origin
	local dir = rayInformation.direction
	local accvec = GetAccuracyVector(cb)
	local caccvec = clientAccuracyVector
	local fr

	-- do result verifications if not already done
	if not isFinal and shotServerReRegistration then

		-- accuracy verification
		-- disabled temporarily
		local cx, cy = math.abs(caccvec.X), math.abs(caccvec.Y)
		local sx, sy = math.abs(accvec.X), math.abs(accvec.Y)
		local ct = {cx, cy}
		local st = {sx, sy}

		for i, v in pairs(ct) do
			if v < st[i] then
				if sx - cx > 6 then
					-- acc diff is bigger than 6, re register shot
					--print("SHOT NOT REGSITERED")
					--return false, accvec
				end
			end
		end

		-- position verification

	end
	
	-- if initial shot is verified, register
	local damage, _, _, damagedChar = RegisterShot(rayInformation, pos, origin, dir, shotRegisteredTime)

	-- if damage was inflicted, fire PlayerDamaged event/signal
	if damage then
		local PlayerDamagedSignal = Signal.GetSignal("PlayerDamaged")
		if PlayerDamagedSignal then PlayerDamagedSignal.Fire(damagedChar, char, damage) end
	end

	return true
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
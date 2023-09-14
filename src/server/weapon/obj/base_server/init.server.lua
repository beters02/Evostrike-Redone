local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Framework = require(ReplicatedStorage.Framework)
--local Signal = require(Framework.shc_signal)

local sharedWeaponFunctions = require(Framework.shfc_sharedWeaponFunctions.Location)

local tool = script.Parent.Parent
local serverModel = tool.ServerModel
local weaponName = string.gsub(tool.Name, "Tool_", "")
local weaponRemoteFunction = tool:WaitForChild("WeaponRemoteFunction")
local weaponRemoteEvent = tool:WaitForChild("WeaponRemoteEvent")
local weaponFolder = game:GetService("ServerScriptService"):WaitForChild("weapon")
local weaponOptions = require(weaponFolder:WaitForChild("config")[string.lower(weaponName)])
local serverStoredVar = {lastFireTime = tick(), nextFireTime = tick()}
if not string.match(string.lower(tool.Name), "knife") then
	serverStoredVar.ammo = {magazine = weaponOptions.ammo.magazine, total = weaponOptions.ammo.total, lastYAcc = 0, accuracy = Vector2.zero}
end
serverStoredVar.vectorOffset = weaponOptions.fireVectorCameraOffset
local timerTypeKeys = {Equip = weaponOptions.equipLength, Fire = weaponOptions.fireRate, Reload = weaponOptions.reloadLength}

local player: Player = tool:WaitForChild("PlayerObject").Value
local char = player.Character or player.CharacterAdded:Wait()

--[[ FUNCTIONS ]]

local equipEndTime
local equipCancel = false

function remote_timer(timerType)
	local endTime = tick()
	local length = timerTypeKeys[timerType]
	if not length then error("Could not find timer " .. tostring(timerType)) end
	endTime += length
	repeat task.wait() until tick() >= endTime
	return true
end

function remote_equipTimerCancel()
	equipCancel = true
end

function remote_equipTimer()
	equipEndTime = tick() + timerTypeKeys.Equip
	repeat task.wait() until tick() >= equipEndTime or equipCancel
	if equipCancel then
		equipCancel = false
		return false
	end
	return true
end

function util_getAccuracy(recoilVector3, currentBullet, speed)
	local acc
	acc, serverStoredVar = sharedWeaponFunctions.calculateAccuracy(currentBullet, recoilVector3, serverStoredVar, speed)
	serverStoredVar.accuracy = acc
	return acc
end

function util_getAccuracyVector(currentBullet)
	return sharedWeaponFunctions.getMovementInaccuracyVector2((weaponOptions.accuracy.firstBullet and currentBullet == 1) or false, player, char.HumanoidRootPart.Velocity.Magnitude, weaponOptions)
end

function util_registerShot(rayInformation, pos, origin, dir, shotRegisteredTime, wallbangDamageMultiplier)
	-- create a fake result to give to server
	local fr = {Instance = rayInformation.instance, Position = pos, Normal = rayInformation.normal, Distance = rayInformation.distance, Material = rayInformation.material}
	-- register shot function
	sharedWeaponFunctions.RegisterShot(player, weaponOptions, fr, origin, dir, shotRegisteredTime, nil, wallbangDamageMultiplier, true, tool, serverModel)
end

function util_registerFireDiff()
    local diff = serverStoredVar.nextFireTime - tick()
    if diff > 0 then
        if diff > 0.04 then
            print(tostring(diff) .. " TIME UNTIL NEXT ALLOWED FIRE")
            return false
        end
    end
    return true
end

function core_equip()
	task.wait()
	local weaponHandle = serverModel.GunComponents.WeaponHandle

	local grip = Instance.new("Motor6D")
	grip.Name = "RightGrip"
	grip.Parent = char.RightHand
	grip.Part0 = char.RightHand
	grip.Part1 = weaponHandle
end

function core_unequip()
	player.Character.HumanoidRootPart.WeaponGrip.Part1 = nil
end

local shotServerReRegistration = false
function core_fire(currentBullet, clientAccuracyVector, rayInformation, shotRegisteredTime, wallbangDamageMultiplier)

	-- check client->server timer diff
	if not util_registerFireDiff() then return false end

	-- update ammo
	serverStoredVar.ammo.magazine -= 1
	serverStoredVar.nextFireTime = tick() + weaponOptions.fireRate

	-- if initial shot is verified, register
	util_registerShot(
		rayInformation,
		rayInformation.position,
		rayInformation.origin,
		rayInformation.direction,
		shotRegisteredTime,
		wallbangDamageMultiplier
	)

	return true
end

function core_reload()
	if serverStoredVar.ammo.total <= 0 then return end
	local newMag
	local defMag = weaponOptions.ammo.magazine
	task.spawn(function()
		local need = defMag - serverStoredVar.ammo.magazine
		if serverStoredVar.ammo.total >= need then
			newMag = serverStoredVar.ammo.magazine + need
			serverStoredVar.ammo.total -= defMag - serverStoredVar.ammo.magazine
		else
			newMag = serverStoredVar.ammo.total
			serverStoredVar.ammo.total = 0
		end
		serverStoredVar.ammo.magazine = newMag
	end)
	remote_timer("Reload")
	return newMag, serverStoredVar.ammo.total
end

--[[{                                 }]


    --      START SCRIPT        --


--[{                                 }]]

-- create actions table for remote invoking
local actions = {Timer = remote_timer, Fire = core_fire, Reload = core_reload, GetAccuracy = util_getAccuracy, EquipTimer = remote_equipTimer, EquipTimerCancel = remote_equipTimerCancel}

weaponRemoteFunction.OnServerInvoke = function(plr, action, ...)
	return actions[action](...)
end

weaponRemoteEvent.OnServerEvent:Connect(function(plr, action, ...)
	actions[action](...)
end)

tool.Equipped:Connect(core_equip)
tool.Unequipped:Connect(core_unequip)
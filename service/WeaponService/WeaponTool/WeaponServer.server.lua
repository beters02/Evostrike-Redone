local tool = script.Parent.Parent
local serverModel = tool:WaitForChild("ServerModel")
local player = tool:WaitForChild("PlayerObject").Value
local character = player.Character

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local EvoPlayer = require(Framework.Module.shared.Modules.EvoPlayer)

local WeaponRemoteEvent: RemoteEvent = tool:WaitForChild("WeaponRemoteEvent")
local WeaponRemoteFunction: RemoteFunction = tool:WaitForChild("WeaponRemoteFunction")
local WeaponServerEquippedEvent: RemoteEvent = tool:WaitForChild("WeaponServerEquippedEvent")

local SharedWeaponFunctions = require(game:GetService("ReplicatedStorage").weapon.fc_sharedWeaponFunctions)

local Module = tool:WaitForChild("WeaponModuleObject").Value
local Options = require(Module).Configuration
local Variables = {equipEndTime = tick(), equipCancel = false, equipping = false}
if Options.ammo then
    Variables.ammo = {magazine = Options.ammo.magazine, total = Options.ammo.total}
end

function ServerEquip()
    task.spawn(EquipTimer)

    local weaponHandle = serverModel.GunComponents.WeaponHandle
	local grip = Instance.new("Motor6D")
	grip.Name = "RightGrip"
	grip.Parent = character.RightHand
	grip.Part0 = character.RightHand
	grip.Part1 = weaponHandle
end

function ServerUnequip()
    if Variables.equipping then
        EquipTimerCancel()
    end

	player.Character.HumanoidRootPart.WeaponGrip.Part1 = nil
end

--@summary Start the Equip Timer.
function EquipTimer()
    local equipped = true

    Variables.equipping = true
    Variables.equipEndTime = tick() + Options.equipLength
    repeat task.wait() until tick() >= Variables.equipEndTime or Variables.equipCancel
    Variables.equipping = false

    if Variables.equipCancel then
        Variables.equipCancel = false
        equipped = false
    end

    WeaponServerEquippedEvent:FireClient(player, equipped)
end

--@summary Cancel the EquipTimer
function EquipTimerCancel()
    Variables.equipCancel = true
end

function ServerFire(currentBullet, clientAccuracyVector, rayInformation, shotRegisteredTime, wallbangDamageMultiplier)
	-- check client->server timer diff
	--if not util_registerFireDiff() then return false end

	-- update ammo
	Variables.ammo.magazine -= 1

    -- create a fake result to give to RegisterShot
	local fr = {
        Instance = rayInformation.instance,
        Position = rayInformation.position,
        Normal = rayInformation.normal,
        Distance = rayInformation.distance,
        Material = rayInformation.material
    }

	SharedWeaponFunctions.RegisterShot(player, Options, fr, rayInformation.origin, rayInformation.direction, shotRegisteredTime, nil, wallbangDamageMultiplier, true, tool, serverModel)
	return true
end

export type KnifeDamageType = "PrimaryStab" | "SecondaryStab" | "Primary" | "Secondary"
function VerifyKnifeDamage(knifeDamageType: KnifeDamageType, damagedHumanoid)
	if player.Character.Humanoid.Health <= 0 then return end
	if knifeDamageType == "PrimaryStab" then
		EvoPlayer:TakeDamage(damagedHumanoid.Parent, Options.damage.primaryBackstab)
	elseif knifeDamageType == "SecondaryStab" then
		EvoPlayer:TakeDamage(damagedHumanoid.Parent, Options.damage.secondaryBackstab)
	elseif knifeDamageType == "Secondary" then
		EvoPlayer:TakeDamage(damagedHumanoid.Parent, Options.damage.secondary)
	else -- "Primary" is default
		EvoPlayer:TakeDamage(damagedHumanoid.Parent, Options.damage.base)
	end
end

function ServerReload()
    if Variables.ammo.total <= 0 then return Variables.ammo.magazine, Variables.ammo.total end
	local newMag
	local defMag = Options.ammo.magazine
	task.spawn(function()
		local need = defMag - Variables.ammo.magazine
		if Variables.ammo.total >= need then
			newMag = Variables.ammo.magazine + need
			Variables.ammo.total -= need
		else
			newMag = Variables.ammo.total + Variables.ammo.magazine
			Variables.ammo.total = 0
		end
		Variables.ammo.magazine = newMag
	end)
	local endTime = tick() + Options.reloadLength
	repeat task.wait() until tick() >= endTime
	return newMag, Variables.ammo.total
end

--@start

WeaponRemoteFunction.OnServerInvoke = function(_plr, action, ...)
    if action == "EquipTimer" then
        return EquipTimer()
    elseif action == "EquipTimerCancel" then
        return EquipTimerCancel()
    elseif action == "Reload" then
        return ServerReload()
	end
end

WeaponRemoteEvent.OnServerEvent:Connect(function(_plr, action, ...)
    if action == "Fire" then
        ServerFire(...)
	elseif action == "VerifyKnifeDamage" then
		VerifyKnifeDamage(...)
	end
end)

tool.Equipped:Connect(ServerEquip)
tool.Unequipped:Connect(ServerUnequip)
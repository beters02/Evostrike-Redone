export type KnifeDamageType = "PrimaryStab" | "SecondaryStab" | "Primary" | "Secondary"

local tool = script.Parent.Parent
local serverModel = tool:WaitForChild("ServerModel")
local weaponHandle = serverModel.GunComponents.WeaponHandle
local player = tool:WaitForChild("PlayerObject").Value
local character = player.Character

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local EvoPlayer = require(Framework.Module.shared.Modules.EvoPlayer)

local WeaponRemoteEvent: RemoteEvent = tool:WaitForChild("WeaponRemoteEvent")
local WeaponRemoteFunction: RemoteFunction = tool:WaitForChild("WeaponRemoteFunction")
local WeaponServerEquippedEvent: RemoteEvent = tool:WaitForChild("WeaponServerEquippedEvent")
local WeaponServerReloadedEvent: RemoteEvent = tool:WaitForChild("WeaponServerReloadedEvent")

local SharedWeaponFunctions = require(game:GetService("ReplicatedStorage").weapon.fc_sharedWeaponFunctions)
local RunService = game:GetService("RunService")

local Module = tool:WaitForChild("WeaponModuleObject").Value
local Options = require(Module).Configuration
local Variables = {equipEndTime = tick(), equipCancel = false, equipping = false, lastEquipTime = false, equipTimeElapsed = 0, reloadTimeElapsed = 0, reloading = false, equipped = false}

local KnifeDamageArray = {
	PrimaryStab = Options.damage.primaryBackstab,
	SecondaryStab = Options.damage.secondaryBackstab,
	Secondary = Options.damage.secondary,
	Primary = Options.damage.base
}

if Options.ammo then
    Variables.ammo = {magazine = Options.ammo.magazine, total = Options.ammo.total}
end

local Grip = character:FindFirstChild("Grip") or Instance.new("Motor6D", character:WaitForChild("RightHand"))
Grip.Name = "Grip"
Grip.Part0 = character.RightHand

--

function handleEquipUpdate(dt)
	if not Variables.equipping then
		return
	end

	Variables.equipTimeElapsed += dt
	if Variables.equipTimeElapsed >= Options.equipLength then
		Variables.equipping = false
		Variables.equipped = true
		WeaponServerEquippedEvent:FireClient(player, true)
	end
end

function doReload()
	local newMag
	local newTotal
	local defMag = Options.ammo.magazine
	local need = defMag - Variables.ammo.magazine

	if Variables.ammo.total >= need then
		newMag = Variables.ammo.magazine + need
		Variables.ammo.total -= need
	else
		newMag = Variables.ammo.total + Variables.ammo.magazine
		Variables.ammo.total = 0
	end

	Variables.ammo.magazine = newMag
	newTotal = Variables.ammo.total

	WeaponServerReloadedEvent:FireClient(player, newMag, newTotal)
end

function handleReloadUpdate(dt)
	if not Variables.reloading then
		return
	end

	if not Variables.equipped then
		resetReloadVar()
		return
	end

	Variables.reloadTimeElapsed += dt

	if Variables.reloadTimeElapsed >= Options.reloadLength then
		Variables.reloading = false
		doReload()
	end
end

function resetReloadVar()
	Variables.reloadTimeElapsed = 0
	Variables.reloading = false
end

--

function Update(dt)
	handleEquipUpdate(dt)
	handleReloadUpdate(dt)
end

function ServerEquip()
	Grip.Part1 = weaponHandle
	Variables.equipTimeElapsed = 0
	Variables.equipping = true
	Variables.equipped = false
end

function ServerUnequip()
	Grip.Part1 = nil
	Variables.equipping = false
	Variables.equipped = false
	resetReloadVar()
end

function ServerFire(currentBullet, clientAccuracyVector, rayInformation, shotRegisteredTime, wallbangDamageMultiplier)
	if character:GetAttribute("SpawnInvincibility") then
		EvoPlayer:SetSpawnInvincibility(character, false)
	end

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

function VerifyKnifeDamage(knifeDamageType: KnifeDamageType, damagedHumanoid)
	if player.Character.Humanoid.Health <= 0 then return end

	if character:GetAttribute("SpawnInvincibility") then
		EvoPlayer:SetSpawnInvincibility(character, false)
	end

	EvoPlayer:TakeDamage(damagedHumanoid.Parent, KnifeDamageArray[knifeDamageType], player.Character, "knife")
end

function ServerReload()
    if Variables.ammo.total <= 0 then return end
	Variables.reloading = true
	Variables.reloadTimeElapsed = 0
end

function ServerAttemptBombPlant()
	
end

--@start
WeaponRemoteFunction.OnServerInvoke = function(_plr, action, ...)
	return false
end

WeaponRemoteEvent.OnServerEvent:Connect(function(_plr, action, ...)
    if action == "Fire" then
        ServerFire(...)
	elseif action == "VerifyKnifeDamage" then
		VerifyKnifeDamage(...)
	elseif action == "Reload" then
        return ServerReload()
	end
end)

RunService.Heartbeat:Connect(Update)
tool.Equipped:Connect(ServerEquip)
tool.Unequipped:Connect(ServerUnequip)
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Weapon = require(Framework.Weapon.Location)
local WeaponModuleLoc = Framework.Weapon.Location
local WeaponRemotes = game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("remote")
local WeaponAddRemoveEvent = WeaponRemotes:WaitForChild("addremove")
local WeaponGetEvent = WeaponRemotes:WaitForChild("get")
local WeaponReplicateEvent = WeaponRemotes:WaitForChild("replicate")

-- Connect Weapon Events
WeaponAddRemoveEvent.OnServerEvent:Connect(function(player, action, ...)
	error("DEPRECATED")
	if action == "Add" then
		Weapon.Add(player, ...)
	elseif action == "Remove" then
		Weapon.Remove(player, ...)
    end
end)

WeaponGetEvent.OnServerInvoke = function(player, action, ...)
	error("DEPRECATED")
	if action == "Options" then
		local weaponOptions = WeaponModuleLoc.Parent.config:FindFirstChild(string.lower(...))
		if not weaponOptions then
			return false
		end
		
		return require(weaponOptions)
	elseif action == "CameraRate" then
		return require(WeaponModuleLoc.Parent.config.camera).updateRate
	elseif action == "FireCameraDownWait" then
		return require(WeaponModuleLoc.Parent.config.camera).fireDownWaitLength
    elseif action == "GetRegisteredWeapons" then
		return Weapon:GetRegisteredWeapons()
	elseif action == "WallbangMaterials" then
		return require(WeaponModuleLoc.Parent.config.wallbangMaterials)
	elseif action == "AllOptions" then
		return Weapon:GetRegisteredWeaponOptions()
	end
end

WeaponReplicateEvent.OnServerEvent:Connect(function(player, functionName, ...)
	error("DEPRECATED")
	for i, v in pairs(game:GetService("Players"):GetPlayers()) do
		if v == player then continue end
		WeaponReplicateEvent:FireClient(v, functionName, ...)
	end
end)
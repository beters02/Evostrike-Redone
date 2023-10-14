local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

-- Weapon Service
local SharedWeaponFunc = require(Framework.Module.shared.weapon.fc_sharedWeaponFunctions)
local WeaponServiceShared = require(Framework.Service.WeaponService.Shared)

-- Connect Replicate Event
-- TEMP: Will Prefer WeaponService.Shared over sharedWeaponFunctions
ReplicatedStorage.Services.WeaponService.Events.Replicate.OnClientEvent:Connect(function(functionName, ...)
	-- TEMP: While converting sharedWeaponFunctions to WeaponService.Shared
	local func = WeaponServiceShared[functionName] or SharedWeaponFunc[functionName]
	if not func then warn(tostring(functionName) .. " is not a SharedWeaponFunction.") return end
	return func(...)
end)
--

-- Gamemode Service
--require(Framework.Service.GamemodeService):Connect()
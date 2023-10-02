local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

-- Ability Service and Classes
local AbilityService = Framework.Service.AbilityService
for _, module in pairs(AbilityService.Ability:GetChildren()) do
    require(module)
end

AbilityService.Events.Replicate.OnClientEvent:Connect(function(action, abilityName, origin, direction, thrower)
    if action == "GrenadeFire" then
        require(AbilityService.Ability[abilityName]):FireGrenade(false, true, origin, direction, thrower)
    end
end)
--

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
require(Framework.Service.GamemodeService):Connect()
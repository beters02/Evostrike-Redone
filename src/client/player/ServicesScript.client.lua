local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

-- Ability Service and Classes
local AbilityService = Framework.Service.AbilityService
local AbilityClasses = {}
for _, module in pairs(AbilityService.Ability:GetChildren()) do
    local _name = string.lower(module.Name)
    AbilityClasses[_name] = require(module)
    AbilityClasses[_name].Options = AbilityClasses[_name].Configuration
    AbilityClasses[_name].Player = game.Players.LocalPlayer
end

local function getAbilityClass(ability: string)
    return AbilityClasses[ability]
end

local function abilityGrenadeFire(abilityName, origin, direction, thrower)
    local abilityClass = getAbilityClass(string.lower(abilityName))
    local fireGrenade = abilityClass.FireGrenadeCore or getAbilityClass("grenade").FireGrenadeCore
    fireGrenade(abilityClass, false, true, origin, direction, thrower)
end

AbilityService.Events.Replicate.OnClientEvent:Connect(function(action, ...)
    if action == "GrenadeFire" then
        abilityGrenadeFire(...)
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
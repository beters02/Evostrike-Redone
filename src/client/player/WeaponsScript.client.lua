-- Wait for player to finish loading before starting the script
local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

-- Load player's Controller and some var before initial Character Load
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

-- Wait for character to load initially ( i actually forget why we have to wait for character )
local _ = player.Character or player.CharacterAdded:Wait()

local SharedWeaponFunc = require(Framework.shfc_sharedWeaponFunctions.Location)
local Shared = require(Framework.Service.WeaponService.Shared)

-- Connect Replicate Event
-- TEMP: Will Prefer WeaponService.Shared over sharedWeaponFunctions
ReplicatedStorage.Services.WeaponService.Events.Replicate.OnClientEvent:Connect(function(functionName, ...)

	-- TEMP: While converting sharedWeaponFunctions to WeaponService.Shared
	local func = Shared[functionName] or SharedWeaponFunc[functionName]
	if not func then warn(tostring(functionName) .. " is not a SharedWeaponFunction.") return end

	return func(...)
end)


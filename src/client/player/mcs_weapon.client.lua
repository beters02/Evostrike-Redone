-- Wait for player to finish loading before starting the script
local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

-- Load player's Controller and some var before initial Character Load
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

-- Wait for character to load initially ( i actually forget why we have to wait for character )
local _ = player.Character or player.CharacterAdded:Wait()

local WeaponRemotes = ReplicatedStorage:WaitForChild("weapon"):WaitForChild("remote")
local WeaponReplicateEvent = WeaponRemotes:WaitForChild("replicate")
local SharedWeaponFunc = require(Framework.shfc_sharedWeaponFunctions.Location)

-- Connect Replicate Event
WeaponReplicateEvent.OnClientEvent:Connect(function(functionName, ...)
	return SharedWeaponFunc[functionName](...)
end)
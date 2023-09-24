local WeaponService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("WeaponService"))
WeaponService:Start()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local WeaponRemotes = game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("remote")
local WeaponGetEvent = WeaponRemotes:WaitForChild("get")
local WeaponReplicateEvent = WeaponRemotes:WaitForChild("replicate")

WeaponGetEvent.OnServerInvoke = function(player, action, ...)
    if action == "GetRegisteredWeapons" then
        return WeaponService:GetRegisteredWeapons()
    end
end

WeaponReplicateEvent.OnServerEvent:Connect(function(player, functionName, ...)
	for i, v in pairs(game:GetService("Players"):GetPlayers()) do
		if v == player then continue end
		WeaponReplicateEvent:FireClient(v, functionName, ...)
	end
end)
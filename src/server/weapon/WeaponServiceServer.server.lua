local WeaponService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("WeaponService"))
WeaponService:Start()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local WeaponRemotes = game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("remote")
local WeaponGetEvent = WeaponRemotes:WaitForChild("get")

WeaponGetEvent.OnServerInvoke = function(player, action, ...)
    if action == "GetRegisteredWeapons" then
        return WeaponService:GetRegisteredWeapons()
    end
end
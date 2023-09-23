local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local tool = script.Parent.Parent

local Types = require(game:GetService("ReplicatedStorage").Services.WeaponService.Types)
local WeaponControllerModule = require(character:WaitForChild("WeaponController"):WaitForChild("Interface")) :: Types.WeaponController
local WeaponController = WeaponControllerModule.currentController
if not WeaponController then
    WeaponControllerModule.Event:Wait()
    WeaponController = WeaponControllerModule.currentController
end
local Weapon = WeaponController:AddWeapon(script:GetAttribute("weaponName"), tool, tool:GetAttribute("IsForceEquip")) :: Types.Weapon
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Types = require(ReplicatedStorage.Services.WeaponService.Types)
local VMSprings = require(Framework.Module.lib.c_vmsprings)

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local tool = script.Parent.Parent
local vmModule = require(character:WaitForChild("ViewmodelScript"):WaitForChild("m_viewmodel"))

local WeaponControllerModule = require(character:WaitForChild("WeaponController"):WaitForChild("Interface")) :: Types.WeaponController
local WeaponController = WeaponControllerModule.currentController
if not WeaponController then
    WeaponControllerModule.Event:Wait()
    WeaponController = WeaponControllerModule.currentController
end

local Weapon = WeaponController:AddWeapon(script:GetAttribute("weaponName"), tool, tool:GetAttribute("IsForceEquip"), script:WaitForChild("Recoil")) :: Types.Weapon

game:GetService("RunService").Stepped:Connect(function(t, dt)
    Weapon._stepDT = dt

    if humanoid.Health <= 0 then
        if Weapon.Options.scope and Weapon.Variables.scoping then
            Weapon.Variables.rescope = false
            Weapon:ScopeOut()
        end
        Weapon.Variables.MainWeaponPartCache:Destroy()
    end
end)
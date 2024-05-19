local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Services.WeaponService.Types)

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local tool = script.Parent.Parent
local stepped_connection

local Weapon

local function getWeaponController()
    local WeaponControllerModule = require(character:WaitForChild("WeaponController"):WaitForChild("Interface"))
    local WeaponController = WeaponControllerModule.currentController
    if not WeaponController then
        WeaponControllerModule.Event:Wait()
        WeaponController = WeaponControllerModule.currentController
    end
    return WeaponController
end

local function addWeapon()
    local controller = getWeaponController()
    return controller:AddWeapon(script:GetAttribute("weaponName"), tool, tool:GetAttribute("IsForceEquip"), script:WaitForChild("Recoil")) :: Types.Weapon
end

local function died()
    if Weapon.Options.scope and Weapon.Variables.scoping then
        Weapon.Variables.rescope = false
        Weapon:ScopeOut()
    end
    Weapon.Variables.MainWeaponPartCache:Destroy()
end

local function stepped(_, dt)
    Weapon._stepDT = dt
    if humanoid.Health <= 0 then
        died()
        stepped_connection:Disconnect()
    end
end

function main()
    Weapon = addWeapon()
    stepped_connection = RunService.Stepped:Connect(stepped)
end

main()
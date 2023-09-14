local WeaponController = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("WeaponController"):WaitForChild("Module"))
WeaponController:Listen()

local player = game:GetService("Players").LocalPlayer
local Died = game.ReplicatedStorage:WaitForChild("main").sharedMainRemotes.deathBE

local function AddController()
    WeaponController:AddWeaponController(player, false, true)
end

player.CharacterAdded:Connect(function(char)
    AddController()
end)
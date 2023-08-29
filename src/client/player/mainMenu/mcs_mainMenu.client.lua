local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local UserInputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenu")
local module = require(script.Parent.cm_mainMenu).initialize(gui)

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.M then
        if player:GetAttribute("Typing") then return end
        if player:GetAttribute("loading") then return end -- if player is loading then dont open menu

        module.toggle()
    end
end)
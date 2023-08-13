local UserInputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenu")
local module = require(script.Parent.cm_mainMenu).initialize(gui)

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.M then
        module.toggle()
    end
end)
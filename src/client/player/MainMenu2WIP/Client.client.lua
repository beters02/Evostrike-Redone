--[[local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenu2")
local module = require(script.Parent)

function init()
    -- todo: display black frame while initting
    -- wait for player to be loaded
    if not player:GetAttribute("Loaded") then
        repeat task.wait(0.5) until player:GetAttribute("Loaded")
    end
    module:Initialize(gui)
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == Enum.KeyCode.N then
            if gui.Enabled then
                module:Close()
            else
                module:Open()
            end
        end
    end)
end

init()]]
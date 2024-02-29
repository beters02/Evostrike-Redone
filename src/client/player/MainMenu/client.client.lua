<<<<<<< Updated upstream
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenu")
local module = require(script.Parent).initialize(gui)
local connectOpenInput = script.Parent.events.connectOpenInput
=======
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Inputs = require(Framework.Module.lib.fc_inputs)
local States = require(Framework.Module.States)

local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenuGui")
local module = require(script.Parent)
local uistate = States:Get("UI")
>>>>>>> Stashed changes

module.conectOpenInput()

Remotes.EnableMainMenu.OnClientEvent:Connect(function(enable)
    if enable then
        module.open()
    else
        module.close()
    end
end)

Remotes.SetMainMenuType.OnClientEvent:Connect(function(mtype)
    module.setMenuType(mtype)
end)

connectOpenInput.Event:Connect(function(mtype)
    module.conectOpenInput()
end)

<<<<<<< Updated upstream
-- New Page Test
--local page2 = require(script.Parent.page2)
--local frame = Instance.new("Frame")

--local invPageTest = page2.new(frame)
=======
-- connect keybinds
UserInputService.InputBegan:Connect(function(input, gp)
    --[[if Inputs.BothKeysDownInput(input, "N", "J") then
        toggle()
    end]]

    if gp or uistate:getOpenUI("Console") then
        return
    end
    if input.KeyCode == Enum.KeyCode.M then
        toggle()
    end
end)
>>>>>>> Stashed changes

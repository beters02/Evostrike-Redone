local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Inputs = require(Framework.Module.lib.fc_inputs)
local States = require(Framework.Module.States)

local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenuGui")
local module = require(script.Parent)
local uistate = States:Get("UI")

local function toggle()
    if gui.Enabled then
        module:Close()
    else
        module:Open()
    end
end

-- todo: display black frame while initting
-- wait for player to be loaded
if not player:GetAttribute("Loaded") then
    repeat task.wait() until player:GetAttribute("Loaded")
end

-- init main menu module
module:Initialize(gui)

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
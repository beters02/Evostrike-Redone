local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
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

local function inputBegan(input, gp)
    if gp or uistate:getOpenUI("Console") then
        return
    end
    if input.KeyCode == Enum.KeyCode.M then
        toggle()
    end
end

if not player:GetAttribute("Loaded") then
    repeat task.wait() until player:GetAttribute("Loaded")
end

module:Initialize(gui)
UserInputService.InputBegan:Connect(inputBegan)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Inputs = require(Framework.Module.lib.fc_inputs)
local States = require(Framework.Module.States)

local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenuGui")
local module = require(script.Parent)
local uistate = States:Get("UI")
local hud = require(player.PlayerScripts:WaitForChild("HUD"))


local openHudOnOpen = true

local hudsDisabled = {}

local function enableHud()
    if hud.gui then
        hud:Enable()
    end
    
    for i, v in pairs(hudsDisabled) do
        v.Enabled = true
    end
    hudsDisabled = {}
end

local function disableHud()
    if hud.gui then
        hud:Disable()
    end
    
    for i, v in pairs(player.PlayerGui:GetChildren()) do
        if v.Enabled and v.Name ~= "MainMenuGui" then
            print(v)
            v.Enabled = false
            table.insert(hudsDisabled, v)
        end
    end
end

local function toggle()
    if gui.Enabled then
        --enableHud()
        module:Close()
    else
        --disableHud()
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

--[[task.delay(0.2, function()
    if module.Gui.Enabled then
        disableHud()
    end
end)]]

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
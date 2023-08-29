--[[
    Custom Input Registration module

    InputBegan and InputEnded are not consistent!
    This module constantly register all bound/needed button inputs
    with some custom functionality.

    Tutorial:



]]

local UserInputService = game:GetService("UserInputService")

local inputs = {}
inputs.__index = inputs
inputs._connections = {}
inputs._player = game:GetService("Players").LocalPlayer
inputs._isProcessing = {}
inputs._loc = inputs._player.PlayerScripts.m_inputs

local bind = require(inputs._loc.bind) -- Imports KeyAction as bind.KeyAction
local process = require(inputs._loc.process)
bind._init(inputs)
inputs._bindModule = bind

inputs.Bind = bind.Bind
inputs.Unbind = bind.Unbind

function inputs._connect()
    inputs._connections.updateMain = game:GetService("RunService").RenderStepped:Connect(function()
        for key, keyActions in pairs(inputs._boundKeyActions) do

            task.spawn(function()
                -- test
                local inputPressed = keyActions._keyProperties.IsMouseKey and UserInputService.IsMouseButtonPressed or UserInputService.IsKeyDown
                local enum = keyActions._keyProperties.IsMouseKey and Enum.UserInputType or Enum.KeyCode
                process.smartProcessKey(inputs, key, inputPressed(UserInputService, enum[key]), keyActions)
            end)

            --[[if keyActions._keyProperties.IsMouseKey then
                process.smartProcessKey(inputs, key, UserInputService:IsMouseButtonPressed(Enum.UserInputType[key]), keyActions)
            else
                process.smartProcessKey(inputs, key, UserInputService:IsKeyDown(Enum.KeyCode[key]), keyActions)
            end]]
        end
    end)
end

function inputs._disconnect()
    inputs._connections.updateMain:Disconnect()
end

--

inputs._connect()

return inputs
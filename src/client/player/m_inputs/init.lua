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
local types = require(inputs._loc.types)
bind._init(inputs)
inputs._bindModule = bind

inputs.Bind = bind.Bind
inputs.Unbind = bind.Unbind
inputs.Process = process
inputs.Types = types

function inputs._connect()
    inputs._connections.updateMain = game:GetService("RunService").RenderStepped:Connect(function()
        process.update(inputs)
    end)
end

function inputs._disconnect()
    inputs._connections.updateMain:Disconnect()
end

--

inputs._connect()

return inputs
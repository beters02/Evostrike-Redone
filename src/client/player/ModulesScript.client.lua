local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

-- [[ INIT MODULES ]]

-- Console
local Console = require(Framework.Module.EvoConsole)
Console:Create(game:GetService("Players").LocalPlayer)
--

-- States
local States = require(Framework.Module.m_states)
local StatesRemoteFunction: RemoteFunction = Framework.Module.m_states.remote.RemoteFunction
local UIState = States.State("UI")
local clientPlayerDataModule = require(Framework.Module.shared.PlayerData.m_clientPlayerData).initialize()
local nxt = tick()
function init_connections()
    StatesRemoteFunction.OnClientInvoke = remote_main
end

function remote_getStateVar(stateName: string, key: string)
    return States._clientClassStore[stateName].var[key]
end

function remote_setStateVar(stateName: string, key: string, value: any)
    States._clientClassStore[stateName].var[key] = value
    return States[stateName].var[key]
end

function remote_main(action, ...)
    if action == "getVar" then
        return remote_getStateVar(...)
    elseif action == "setVar" then
        return remote_setStateVar(...)
    end
end

-- responsible for handling UI state properties
-- ex: if a UI is enabled in which the MouseIcon is enabled with, the MouseIcon stays enabled
-- Connect Mouse Icon Update
UIState:changed(function()
    local should = UIState:shouldMouseBeEnabled()
    UserInputService.MouseIconEnabled = should
    UserInputService.MouseBehavior = should and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
end)
--

local update = RunService.RenderStepped:Connect(function()
    if tick() < nxt then return end
    nxt = tick() + 10
end)

Players.PlayerRemoving:Connect(function(plr)
    if player == plr then
        update:Disconnect()
        clientPlayerDataModule:Save()
    end
end)
--

-- Sounds
local SoundsReplicate = Framework.Module.Sound:WaitForChild("remote"):WaitForChild("replicate")
SoundsReplicate.OnClientEvent:Connect(function(action, sound, whereFrom)
    if not sound then return end
    if action == "Play" then
        local volume = whereFrom
        if volume then sound.Volume = volume end
        sound:Play()
    elseif action == "Clone" then
        local c = sound:Clone()
        c.Parent = whereFrom
        c:Play()
        Debris:AddItem(c, c.TimeLength + 0.05)
    elseif action == "Stop" then
        sound:Stop()
    end
end)
--

-- Ragdolls
local Ragdolls = require(Framework.Module.Ragdolls)

-- Evo Modules
require(Framework.Module.EvoMMWrapper)
Framework.Module.EvoMMWrapper.Remote.OnClientEvent:Connect(function()
end)

task.delay(2, function()
    require(Framework.Module.EvoPlayer)
end)
--
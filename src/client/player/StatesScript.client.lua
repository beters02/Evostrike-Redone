local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local UserInputService = game:GetService("UserInputService")
local Framework = require(game:GetService("ReplicatedStorage").Framework)
local statesloc = game:GetService("ReplicatedStorage"):WaitForChild("states")
local states = require(Framework.shm_states.Location)
local mainrf: RemoteFunction = statesloc:WaitForChild("remote").mainrf

function init_connections()
    mainrf.OnClientInvoke = remote_main
end

function remote_getStateVar(stateName: string, key: string)
    return states._clientClassStore[stateName].var[key]
end

function remote_setStateVar(stateName: string, key: string, value: any)
    states._clientClassStore[stateName].var[key] = value
    return states[stateName].var[key]
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
local UIState = states.State("UI")

-- Connect Mouse Icon Update
UIState:changed(function()
    local should = UIState:shouldMouseBeEnabled()
    UserInputService.MouseIconEnabled = should
    UserInputService.MouseBehavior = should and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
end)
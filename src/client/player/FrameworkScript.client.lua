local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local Console = require(Framework.Module.EvoConsole)

local SoundsReplicate = Framework.Module.Sound:WaitForChild("remote"):WaitForChild("replicate")
require(Framework.Module.EvoMMWrapper)
task.delay(2, function() require(Framework.Module.EvoPlayer) end)


-- Evo MM
Framework.Module.EvoMMWrapper.Remote.OnClientEvent:Connect(function() end)
--

-- Console
Console:Create(game:GetService("Players").LocalPlayer)
--

-- States
local States = require(Framework.Module.States)
local UIState = States:Get("UI")

--@summary responsible for handling UI state properties (mouseIconEnabled)
UIState:changed(function()
    local should = UIState:shouldMouseBeEnabled()
    UserInputService.MouseIconEnabled = should
    UserInputService.MouseBehavior = should and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
end)

Framework.Module.EvoPlayer.Events.PlayerDiedBindable.Event:Connect(function()
    UIState:clearOpenUIs()
end)
--

-- PlayerData
--

-- EvoEconomy
require(Framework.Module.EvoEconomy)
--

-- Sounds
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

-- Weapon Service
local SharedWeaponFunc = require(Framework.Module.shared.weapon.fc_sharedWeaponFunctions)
local WeaponServiceShared = require(Framework.Service.WeaponService.Shared)

-- Connect Replicate Event
-- TEMP: Will Prefer WeaponService.Shared over sharedWeaponFunctions
ReplicatedStorage.Services.WeaponService.Events.Replicate.OnClientEvent:Connect(function(functionName, ...)
	-- TEMP: While converting sharedWeaponFunctions to WeaponService.Shared
	local func = WeaponServiceShared[functionName] or SharedWeaponFunc[functionName]
	if not func then warn(tostring(functionName) .. " is not a SharedWeaponFunction.") return end
	return func(...)
end)
--
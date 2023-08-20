local Players = game:GetService("Players")

local module = require(script.Parent:WaitForChild("m_crosshair"))
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hud = player.PlayerGui:WaitForChild("HUD")

module = module.initialize(hud)

module:enable()
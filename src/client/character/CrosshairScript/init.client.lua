local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

local module = require(script:WaitForChild("m_crosshair"))
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hud = player.PlayerGui:WaitForChild("HUD")

module = module.initialize(hud)

module:enable()
module:connect()

for _, v in pairs({"red", "blue", "green", "thickness", "gap", "size"}) do
    PlayerData:PathValueChanged("options.crosshair." .. v, function(new)
        module[v] = new
        module:updateCrosshair(v, new)
    end)
end

script:WaitForChild("UpdateCrosshair").Event:Connect(function()
    module:updateCrosshair()
end)
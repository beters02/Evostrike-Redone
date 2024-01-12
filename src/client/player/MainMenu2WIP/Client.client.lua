local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenu")
local module = require(script.Parent)

function init()
    -- todo: display black frame while initting
    -- wait for player to be loaded
    if not player:GetAttribute("Loaded") then
        repeat task.wait(0.5) until player:GetAttribute("Loaded")
    end
    module:Initialize()
end

init()
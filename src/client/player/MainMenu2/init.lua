local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end
local gui = player.PlayerGui:WaitForChild("MainMenu")
local page = script:WaitForChild("Page")

local MainMenu = {}

function init()
    require(page).init(MainMenu)
    return MainMenu
end

return init()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer

if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local gui = player.PlayerGui:WaitForChild("MainMenu")
local module = require(script.Parent).initialize(gui)

module.conectOpenInput()

ReplicatedStorage:WaitForChild("Remotes").EnableMainMenu.OnClientEvent:Connect(function(enable)
    if enable then
        module.open()
    else
        module.close()
    end
end)

ReplicatedStorage:WaitForChild("Remotes").SetMainMenuType.OnClientEvent:Connect(function(mtype)
    module.setMenuType(mtype)
end)

script.Parent.events.connectOpenInput.Event:Connect(function(mtype)
    module.conectOpenInput()
end)
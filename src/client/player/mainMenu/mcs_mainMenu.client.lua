local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer

if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local gui = player.PlayerGui:WaitForChild("MainMenu")
local module = require(script.Parent.cm_mainMenu).initialize(gui)

ReplicatedStorage:WaitForChild("main").sharedMainRemotes.EnableMainMenu.OnClientEvent:Connect(function(enable)
    if enable then
        module.open()
    else
        module.close()
    end
end)

script.Parent.EnableMenuBindable.Event:Connect(function(enable)
    if enable then
        module.open()
    else
        module.close()
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.M then
        if player:GetAttribute("Typing") then return end
        if player:GetAttribute("loading") then return end -- if player is loading then dont open menu

        -- if player in the lobby screen and has not spawned, don't let them close the menu
        if module.var.opened and module.gui:GetAttribute("NotSpawned") then
            return
        end

        module.toggle()
    end
end)


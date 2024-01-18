local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("MainMenuGui")

task.wait()

print("initting main meun!!")
local module = require(script.Parent).initialize(gui)
local connectOpenInput = script.Parent.events.connectOpenInput

module.conectOpenInput()

Remotes.EnableMainMenu.OnClientEvent:Connect(function(enable)
    if enable then
        module.open()
    else
        module.close()
    end
end)

Remotes.SetMainMenuType.OnClientEvent:Connect(function(mtype)
    module.setMenuType(mtype)
end)

connectOpenInput.Event:Connect(function(mtype)
    module.conectOpenInput()
end)

-- New Page Test
--local page2 = require(script.Parent.page2)
--local frame = Instance.new("Frame")

--local invPageTest = page2.new(frame)
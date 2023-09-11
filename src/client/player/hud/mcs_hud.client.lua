local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hud = require(script.Parent:WaitForChild("m_hud"))

hud = hud.initialize(player)

player.CharacterAdded:Connect(function(char)
    hud:ConnectPlayer()

    local hum = char:WaitForChild("Humanoid")
    hum.Died:Once(function()
        hud:DisconnectPlayer()
    end)
end)

if player.Character then
    hud:ConnectPlayer()

    local hum = player.Character:WaitForChild("Humanoid")
    hum.Died:Once(function()
        hud:DisconnectPlayer()
    end)
end
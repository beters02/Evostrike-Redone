local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local didInit = false
local _ = player.Character or player.CharacterAdded:Wait()
local hud = require(script.Parent)
hud = hud.initialize(player)

-- update version from workspace
local version = workspace:GetAttribute("Version")
hud.gui:WaitForChild("Version").Text = "Evostrike Version " .. tostring(version)

local function initCharHud(char)
    if not didInit then
        didInit = true
    end
    hud:ConnectPlayer()

    local hum = char:WaitForChild("Humanoid")
    hum.Died:Once(function()
        hud:DisconnectPlayer()
    end)
end

local function start()
    player.CharacterAdded:Connect(initCharHud)
    if player.Character and not didInit then
        initCharHud(player.Character)
    end
end

start()
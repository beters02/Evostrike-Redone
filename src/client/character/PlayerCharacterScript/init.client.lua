local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local TweenService = game:GetService("TweenService")
local Playerdata = require(Framework.shm_clientPlayerData.Location)

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local health = hum.Health

-- Register Death & Damage
local DiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local DiedBind = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE")
local DamagedEvent = script:WaitForChild("PlayerDamaged")

hum.Died:Connect(function()
    local killer = char:FindFirstChild("DamageTag") and char.DamageTag.Value or false
    DiedEvent:FireServer(killer)
    DiedBind:Fire(killer)
end)

hum.Changed:Connect(function(property)
    if property == "Health" then
        if hum.Health < health then
            DamagedEvent:FireServer(hum.Health, health - hum.Health, char:GetAttribute("lastHitPart"))
        end
        health = hum.Health
    end
end)

-- Initialize Camera Variables
task.delay(1, function()
    -- initial
    local deffov = Playerdata:Get("options.camera.FOV")

    -- smoothen out fov transfer if necessary
    local function smooth(newFov)
        TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {FieldOfView = newFov}):Play()
    end

    if workspace.CurrentCamera.FieldOfView ~= deffov then
        smooth(deffov)
    end

    -- FOV changed
    local fovChangeConn = Playerdata:Changed("options.camera.FOV", function(newValue)
        deffov = newValue
        smooth(deffov)
    end)
end)

-- Set Character CanCollide to False
-- Do this later so people dont fall thru floor?
task.delay(3, function()
    for i, v in pairs(char:GetDescendants()) do
        if v:IsA("Part") or v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
end)


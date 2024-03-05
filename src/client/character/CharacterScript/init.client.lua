local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local TweenService = game:GetService("TweenService")
local PlayerData = require(Framework.Module.PlayerData)
local EvoPlayer = Framework.Module.EvoPlayer

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

-- Register Death & Damage
local DiedEvent = EvoPlayer.Events:WaitForChild("PlayerDiedRemote")
local DiedBind = EvoPlayer.Events:WaitForChild("PlayerDiedBindable")
local FromEvoPlayerDamagedEvent = char:WaitForChild("EvoPlayerDamagedEvent")
local DamagedAnimationObj = char:WaitForChild("DamagedAnimation")
local DamagedAnimation = hum.Animator:LoadAnimation(DamagedAnimationObj)

hum.Died:Connect(function()
    local killer = char:FindFirstChild("DamageTag") and char.DamageTag.Value or false
    local weaponUsed = char:GetAttribute("WeaponUsedToKill")
    DiedEvent:FireServer(killer, weaponUsed)
    DiedBind:Fire(killer)
end)

FromEvoPlayerDamagedEvent.OnClientEvent:Connect(function()
    DamagedAnimation:Play()
end)

-- Initialize Camera Variables
task.delay(1, function()
    -- initial
    local deffov = PlayerData:GetPath("options.camera.FOV")

    -- smoothen out fov transfer if necessary
    local function smooth(newFov)
        TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {FieldOfView = newFov}):Play()
    end

    if workspace.CurrentCamera.FieldOfView ~= deffov then
        smooth(deffov)
    end

    -- FOV changed
    PlayerData:PathValueChanged("options.camera.FOV", function(newValue, a, b, c)
        print(a)
        print(b)
        print(c)
        print(newValue)
        deffov = newValue
        smooth(deffov)
    end)
end)

-- Set Character CanCollide to False
-- Do this later so people dont fall thru floor?
for _, v in pairs(char:GetDescendants()) do
    if v:IsA("Part") or v:IsA("BasePart") then
        v.CanCollide = false
    end
end
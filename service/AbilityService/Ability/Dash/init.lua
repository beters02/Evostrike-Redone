local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local RunService = game:GetService("RunService")

local Dash = {
    Options = {
        -- data
        name = "Dash",
        inventorySlot = "primary",

        -- gemeral
        cooldownLength = 5,
        uses = 100,

        -- camera recoil
        -- absr = Absolute Value Random
        -- rtabsr = Random to Absolute Value Random
        useCameraRecoil = {
            downDelay = 0.07,

            up = "0.04-0.06rtabsr",
            side = "0.04-0.06rtabsr",
            shake = "0.04-0.06rtabsr",

            speed = 4,
            force = 60,
            damp = 4,
            mass = 9
        },

        -- dash-specific movement
        strength = 55,
        upstrength = 25,
        jumpingUpstrengthModifier = 0.5,
        landingMovementDecreaseFriction = 0.9,
        landingMovementDecreaseLength = 0.3,
    }
}

if RunService:IsClient() then
    Dash.PlayerData = require(ReplicatedStorage.PlayerData.m_clientPlayerData)
end

--@override
function Dash:Use()

    print('PENIS')
    
    -- play sounds
    Sound.PlayReplicatedClone(self.Module.Assets.Sounds.Whisp, self.Player.Character.PrimaryPart)
    Sound.PlayReplicatedClone(self.Module.Assets.Sounds.Woosh, self.Player.Character.PrimaryPart)

    -- play fov tween
    local playerfov = Dash.PlayerData:Get("options.camera.FOV")
    task.spawn(function()
        local tween = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {FieldOfView = playerfov * 1.2})
        local conn
        local completed = false
        local t = tick() + 2

        tween:Play()
        conn = tween.Completed:Once(function()
            completed = true
            conn = nil
        end)

        repeat task.wait() until tick() >= t or completed
        if conn then conn:Disconnect() end
        conn = nil
        
        local newfov = workspace.CurrentCamera.FieldOfView
        tween:Destroy()
        workspace.CurrentCamera.FieldOfView = newfov

        tween = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {FieldOfView = playerfov})
        tween:Play()
        tween.Completed:Wait()
        tween:Destroy()
    end)
    
    -- movement script functionality
    self.Player.Character.MovementScript.Events.Dash:Fire(self.Options.strength, self.Options.upstrength, self.Options.jumpingUpstrengthModifier)
end

return Dash
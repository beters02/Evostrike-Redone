local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.shm_sound.Location)
local TweenService = game:GetService("TweenService")
local Math = require(Framework.shfc_math.Location)
local Strings = require(Framework.shfc_strings.Location)

local Dash = {

    -- movement settings
    strength = 50,
    upstrength = 25,
    jumpingUpstrengthModifier = 0.5,

    -- gemeral settings
    cooldownLength = 5,
    uses = 100,

    -- absr = Absolute Value Random
    -- rtabsr = Random to Absolute Value Random
    useCameraRecoil = {
        downDelay = 0.07,

        up = "0.05-0.1rtabsr",
        side = "0.05-0.1rtabsr",
        shake = "0.05-0.1rtabsr",

        speed = 4,
        force = 60,
        damp = 4,
        mass = 9
    },

    -- data settings
    abilityName = "Dash",
    inventorySlot = "primary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
}

function Dash:Use()
    self.uses -= 1
    self.startCF = self.player.Character.PrimaryPart.CFrame

    task.spawn(function()
        local canUse = self:ServerUseVarCheck()
        if not canUse then self:UseFailed() end
    end)

    -- play sounds
    Sound.PlayReplicatedClone(self._sounds.Whisp, self.player.Character.PrimaryPart)
    Sound.PlayReplicatedClone(self._sounds.Woosh, self.player.Character.PrimaryPart)

    -- play fov tween
    local playerfov = self.m_playerdata:Get("options.camera.FOV")

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

    -- play camera recoil
    self:UseCameraRecoil()
    
    self.player.Character.MovementScript.Events.Dash:Fire(Dash.strength, Dash.upstrength, Dash.jumpingUpstrengthModifier)
end

function Dash:UseCameraRecoil()

    -- parse absr
    local _parse = {self.useCameraRecoil.up, self.useCameraRecoil.side, self.useCameraRecoil.shake}
    for i, v in pairs(_parse) do
        if type(v) == "string" then
            local _parsedStr = Strings.getParsedStringContents(v)

            if _parsedStr.action == "absr" then
                _parse[i] = Math.absr(_parsedStr.numbers[1])
            elseif _parsedStr.action == "rtabsr" then
                _parse[i] = Math.absr(math.random(_parsedStr.numbers[1] * 100, _parsedStr.numbers[2] * 100)/100)
            elseif _parsedStr.action == "r" then
                _parse[i] = math.random(_parsedStr.numbers[1] * 100, _parsedStr.numbers[2] * 100)/100
            end

        end
    end

    -- shoves

    -- get shove based on movement direction
    local moveVelocity = self.player.Character.HumanoidRootPart.Velocity
    moveVelocity = moveVelocity.Magnitude > 0 and moveVelocity.Unit or Vector3.one
    local shoveDir = self.player.Character.HumanoidRootPart.CFrame:VectorToObjectSpace(moveVelocity)

    local shove = Vector3.new(_parse[1] * math.min(0.5, shoveDir.Y), _parse[2] * Math.fixedMin(shoveDir.X, 0.7), _parse[3])
    self.cameraSpring:shove(shove)
    task.delay(self.useCameraRecoil.downDelay or 0.07, function()
        self.cameraSpring:shove(-shove)
    end)

end

function Dash:UseFailed()
    self.player.Character:SetPrimaryPartCFrame(self.startCF)
end

return Dash
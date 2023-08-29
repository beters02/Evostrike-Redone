--[[ Base AbilityClass ]]

--[[
    ServerUseVarCheck must be called in the custom AbilityClass:Use() function.
    Must also have AbilityClass:UseFailed()
]]

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local RunService = game:GetService("RunService")
local VMSprings = require(Framework.shc_vmsprings.Location)
local Math = require(Framework.shfc_math.Location)
local Strings = require(Framework.shfc_strings.Location)

local Base = {}
Base.__index = Base

function Base.new(abilityClassModule)
    if not abilityClassModule then warn("Must specify AbilityClassModule") return end
    local self = require(abilityClassModule)

    -- grenade base class inheritance
    if self.isGrenade then
        for i, v in pairs(require(abilityClassModule.GrenadeBase)) do
            if not self[i] then self[i] = v end
        end
    end

    setmetatable(self, Base)

    -- init use spring if necesssary
    if self.useCameraRecoil then
        self:InitCameraRecoil()
    end

    -- playerdata
    self.m_playerdata = require(Framework.shm_clientPlayerData.Location)

    return self
end

function Base:ServerUseVarCheck()
    local useSuccess, err = self.remoteFunction:InvokeServer("CanUse")
    if not useSuccess then
        return false, warn("ABILITY USE ERROR, " .. err)
    end

    local newUses = useSuccess
    self.uses = newUses
    return self.uses
end

function Base:StartClientCooldown()
    return task.spawn(function()

        -- set image color to unequipped
        self:SetIconColorEquipped(false)

        for i = self.cooldownLength, 0, -1 do
            if i == 0 then

                -- reset cooldown variable
                self.cooldown = false

                -- reset key text to key
                self.frame.Key.Text = self.key

                -- set image color to equipped
                self:SetIconColorEquipped(true)
                break
            end

            -- set key text to cooldown number
            self.frame.Key.Text = tostring(i)

            task.wait(1)
        end
    end)
end

function Base:SetIconColorEquipped(equipped)
    self.frame.IconImage.ImageColor3 = equipped and self.frame:GetAttribute("EquippedColor") or self.frame:GetAttribute("UnequippedColor")
end

--

function Base:InitCameraRecoil()
    self.cameraRecoil = true
    self.cameraSpring = VMSprings:new(self.useCameraRecoil.mass, self.useCameraRecoil.force, self.useCameraRecoil.damp, self.useCameraRecoil.speed)
    self:ConnectCameraRecoil()
end

function Base:ConnectCameraRecoil()
    self.cameraRecoilUpdate = RunService.RenderStepped:Connect(function(dt)
        local update = self.cameraSpring:update(dt)
        workspace.CurrentCamera.CFrame *= CFrame.Angles(update.X, update.Y, update.Z)
    end)
    return self.cameraRecoilUpdate
end

function Base:DisconnectCameraRecoil()
    self.cameraRecoilUpdate:Disconnect()
end

function Base:UseCameraRecoil()

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
    local shove = Vector3.new(_parse[1], _parse[2], _parse[3])
    self.cameraSpring:shove(shove)
    task.delay(self.useCameraRecoil.downDelay or 0.07, function()
        self.cameraSpring:shove(-shove)
    end)

end

return Base
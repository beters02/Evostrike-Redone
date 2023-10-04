local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Framework = require(ReplicatedStorage.Framework)
local AbilityObjects = Framework.Service.AbilityService.Ability.Satchel.Assets

local Satchel = {
    Configuration = {
        -- data
        name = "Satchel",
        inventorySlot = "secondary",
        isGrenade = true,
        
        -- genral
        cooldownLength = 3,
        uses = 100,
        usingDelay = 0.3, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time

        -- grenade
        grenadeThrowDelay = 0.36,
        acceleration = 10,
        speed = 150,
        gravityModifier = 0.5,
        startHeight = 2,

        -- animation / holding
        clientGrenadeSize = Vector3.new(0.328, 1.047, 0.359),
        grenadeVMOffsetCFrame = false, -- if you have a custom animation already, set this to false
        throwAnimFadeTime = 0.18,
        throwFinishSpringShove = Vector3.new(-0.4, -0.5, 0.2),

        -- satchel specific
        lengthBeforePop = 2.5,
        explosionMaxDamage = 70,
        explosionMaxRadius = 7,
        explosionStrength = 150,

        -- absr = Absolute Value Random
        -- rtabsr = Random to Absolute Value Random
        useCameraRecoil = {
            downDelay = 0.07,

            up = 0.03,
            side = 0.011,
            shake = "0.015-0.035rtabsr",

            speed = 4,
            force = 60,
            damp = 4,
            mass = 9
        }
    },
    AbilityObjects = AbilityObjects
}

--@override
--@summary Required Grenade Function RayHit
-- class, casterPlayer, casterThrower, result, velocity, grenade
function Satchel.RayHit(_, _, _, _, _, grenade)
    if grenade then grenade.Anchored = true end
end

--@override
function Satchel:FireGrenadePost(_, _, _, _, thrower, grenade)
    if self.satchelConnection then self.satchelConnection:Disconnect() end
    grenade:SetAttribute("IsPopped", false)

    local _t = tick() + self.Options.timeBeforeSatchelExplodes
    local blasted = false
    self.satchelConnection = RunService.RenderStepped:Connect(function()
        if not grenade or tick() >= _t or blasted then
            self.satchelConnection:Disconnect()
            return
        end

        if UserInputService:IsKeyDown(Enum.KeyCode[self.key]) then
            blasted = true
            self:Blast()
        end
    end)

    task.delay(self.Options.lengthBeforePop, function()
        if grenade and not grenade:GetAttribute("IsPopped") then
            self:Blast(grenade)
        end
    end)
end

function Satchel:Blast(thrower, grenade)
    grenade:SetAttribute("IsPopped", true)

    if thrower.Character then
        local _p = RaycastParams.new()
        _p.FilterType = Enum.RaycastFilterType.Exclude
        _p.FilterDescendantsInstances = {grenade}
        local ray = workspace:Raycast(grenade.CFrame.Position, (thrower.Character.HumanoidRootPart.CFrame.Position - grenade.CFrame.Position).Unit * self.Options.explosionMaxRadius, _p)

        print(ray.Instance:FindFirstAncestorOfClass("Model"))
        if ray.Instance:FindFirstAncestorOfClass("Model") == self.player.Character then
            thrower.Character.HumanoidRootPart:ApplyImpulse((thrower.Character.HumanoidRootPart.CFrame.Position - grenade.CFrame.Position).Unit * ray.Distance * self.Options.explosionStrength)
        end
        print(ray)
    end
    
    grenade:Destroy()
end

return Satchel
--@summary Create a Caster for a Grenade Ability Module
--@purpose Rule out require recursion in Grenade Class

local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local FastCast = require(Framework.Module.lib.c_fastcast)

local Caster = {}

--@summary Create the Module's Grenade Caster, stored in the Class
--@param   self: AbilityClass -- The AbilityClass which is requesting the caster creation
function Caster.new(self)
    self.caster = FastCast.new()
	self.castBehavior = FastCast.newBehavior()
	self.castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity * self.Configuration.gravityModifier, 0)
	self.castBehavior.AutoIgnoreContainer = false
	self.castBehavior.CosmeticBulletContainer = workspace.Temp
	self.castBehavior.CosmeticBulletTemplate = self.AbilityObjects.Models.Grenade
    self.caster.RayHit:Connect(function(casterThatFired, result, segmentVelocity, cosmeticBulletObject)
        self.RayHit(self.caster, Players.LocalPlayer, casterThatFired, result, segmentVelocity, cosmeticBulletObject)
    end)
    self.caster.LengthChanged:Connect(function(_, lastPoint, direction, length, _, bullet) -- cast, lastPoint, direction, length, velocity, bullet
        if bullet then
            local bulletLength = bullet.Size.Z/2
            local offset = CFrame.new(0, 0, -(length - bulletLength))
            bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
        end
    end)
    self.caster.CastTerminating:Connect(function()end)
end

function Caster.getLocalParams()
    local locparams = RaycastParams.new()
    locparams.CollisionGroup = "Grenades"
    locparams.FilterType = Enum.RaycastFilterType.Exclude
    locparams.FilterDescendantsInstances = {workspace.CurrentCamera, Players.LocalPlayer.Character}
    return locparams
end

function Caster.getOtherParams(thrower)
    local otherCastParams = RaycastParams.new()
    otherCastParams.CollisionGroup = "Grenades"
    otherCastParams.FilterType = Enum.RaycastFilterType.Exclude
    otherCastParams.FilterDescendantsInstances = {thrower.Character}
    return otherCastParams
end

return Caster
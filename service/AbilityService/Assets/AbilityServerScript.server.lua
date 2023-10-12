local Framework = require(game.ReplicatedStorage.Framework)
local Module = script.Parent:WaitForChild("ModuleObject").Value
local RemoteFunction = script.Parent:WaitForChild("Events"):WaitForChild("RemoteFunction")
local FastCast = require(Framework.Module.lib.c_fastcast)
local player = script.Parent:WaitForChild("PlayerObject").Value
local Ability = require(Framework.Service.AbilityService.Ability).new(player, Module)

local Shared = {
    FireGrenadeServer = function(_, ...)
        return Ability:FireGrenade(...)
    end
}

function InitCaster()
    local caster = FastCast.new()
    local castBeh = FastCast.newBehavior()

	castBeh.Acceleration = Vector3.new(0, -workspace.Gravity * Ability.Options.gravityModifier, 0)
	castBeh.AutoIgnoreContainer = false
	castBeh.CosmeticBulletContainer = workspace.Temp
	castBeh.CosmeticBulletTemplate = Module:WaitForChild("Assets").Models.Grenade
    caster.RayHit:Connect(function(...)
        Ability:RayHitCore(...)
    end)-- function(casterThatFired, result, segmentVelocity, cosmeticBulletObject)
    --self.RayHit(self.caster, Players.LocalPlayer, casterThatFired, result, segmentVelocity, cosmeticBulletObject, Caster.abilityClass)
    caster.LengthChanged:Connect(Ability.LengthChanged)
    caster.CastTerminating:Connect(Ability.CastTerminating)

    Ability.Caster = caster
    Ability.CastBehavior = caster
end

function Init()
    if Ability.isGrenade then
        InitCaster()
    end
    RemoteFunction.OnServerInvoke = function(player, action, ...)
        return Shared[action](player, ...)
    end
end
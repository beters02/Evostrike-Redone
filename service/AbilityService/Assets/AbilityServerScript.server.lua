local Framework = require(game.ReplicatedStorage.Framework)
local Module = script.Parent:WaitForChild("ModuleObject").Value
local RemoteFunction = script.Parent:WaitForChild("Events"):WaitForChild("RemoteFunction")
local FastCast = require(Framework.Module.lib.c_fastcast)
local player = script.Parent:WaitForChild("PlayerObject").Value
local Ability = require(Framework.Service.AbilityService.Ability).new(player, Module, true)

local Shared = {
    FireGrenadeServer = function(_, ...)
        Framework.Service.AbilityService.Events.RemoteEvent:FireAllClients("GrenadeFire", Ability.Options.name, player, ...)
        --local grenade =  Ability:FireGrenade(...)
    end
}

function InitCaster()
    local caster = FastCast.new()
    caster.SimulateBeforePhysics = true
    local castBeh = FastCast.newBehavior()

	castBeh.Acceleration = Vector3.new(0, -workspace.Gravity * Ability.Options.gravityModifier, 0)
	castBeh.AutoIgnoreContainer = false
	castBeh.CosmeticBulletContainer = workspace.Temp
	castBeh.CosmeticBulletTemplate = Module:WaitForChild("Assets").Models.Grenade
    caster.RayHit:Connect(function(...)
        Ability:RayHitCore(...)
    end)
    caster.LengthChanged:Connect(function(...)
        Ability:LengthChanged(...)
    end)
    caster.CastTerminating:Connect(function(...)
        Ability.CastTerminating(...)
    end)

    Ability.Caster = caster
    Ability.CastBehavior = castBeh
end

function Init()
    if Ability.Options.isGrenade then
        InitCaster()
    end
    RemoteFunction.OnServerInvoke = function(player, action, ...)
        return Shared[action](player, ...)
    end
end

Init()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local FastCastTypes = require(Framework.Module.lib.c_fastcast.TypeDefinitions)

export type GrenadeOptions = {
    isGrenade: boolean,
    grenadeThrowDelay: number,
    acceleration: number,
    speed: number,
    gravityModifier: number,
    startHeight: number,
    throwAnimFadeTime: number,
    clientGrenadeSize: Vector3,
    behaviorId: string,
}

local GrenadeOptions = {}
function GrenadeOptions.new(name: string, overwrite: table?)
    local op = {
        isGrenade = true,
        grenadeThrowDelay = 0.2,
        acceleration = 10,
        speed = 150,
        gravityModifier = 0.2,
        startHeight = 2,
        grenadeVMOffsetCFrame = CFrame.Angles(0,math.rad(80),0) + Vector3.new(0, 0, 0.4),
        throwAnimFadeTime = 0.18,
        behaviorId = name
    }
    if overwrite then
        for i, v in pairs(overwrite) do
            op[i] = v
        end
    end
    return op :: GrenadeOptions
end

export type Grenade = {
    Caster: FastCastTypes.Caster,
    Behavior: FastCastTypes.FastCastBehavior,
    Options: GrenadeOptions,
    Connections: table,
    CurrentGrenadeObject: MeshPart|Part|nil,

    Fire: (mouseHit: any, ...any) -> (),
}

return {GrenadeOptions = GrenadeOptions}
--[[
    Purpose: Unify all Grenade functionality into a single module
    Description: Create a Grenade Object on the Client that will automatically replicate to everybody on the server.
--]]

local Players = game:GetService("Players")
local Types = require(script:WaitForChild("Types"))
local Caster = require(script:WaitForChild("Caster"))

local grenades = {}
grenades.Types = Types

function grenades:CreateGrenade(options: table?, objects: Folder)
    local grenade: Types.Grenade = {
        Caster = Caster:GetCaster(Players.LocalPlayer),
        Behavior = Caster:GetCastBehavior(Players.LocalPlayer, options, objects),
        Options = Types.GrenadeOptions.new(options.name, options),
        Connections = {},
        CurrentGrenadeObject = nil
    }

    Caster:SetCasterRayHit(Players.LocalPlayer, options.RayHit, grenade, Players.LocalPlayer)

    grenade.Fire = function(mouseHit)
        local startLv = Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
        local origin = Players.LocalPlayer.Character.HumanoidRootPart.Position + (startLv * 1.5) + Vector3.new(0, grenade.Options.startHeight, 0)
        local direction = (mouseHit.Position - origin).Unit
        local cast = Caster:FireCaster(grenade.Options.behaviorId, origin, direction, direction * grenade.Options.speed)
        grenade.CurrentGrenadeObject = cast.RayInfo.CosmeticBulletObject
    end

    grenade.Destroy = function()
        Caster:Remove(Players.LocalPlayer)
        for i, v in pairs(grenade.Connections) do
            v:Disconnect()
        end
    end

    return grenade :: Types.Grenade
end

return grenades
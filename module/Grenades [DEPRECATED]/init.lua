--[[
    Purpose: Unify all Grenade functionality into a single module
    Description: Create a Grenade Object on the Client that will automatically replicate to everybody on the server.
--]]

local Players = game:GetService("Players")
local Types = require(script:WaitForChild("Types"))
local Caster = require(script:WaitForChild("Caster"))

local grenades = {}
grenades.Types = Types

function grenades:CreateGrenade(abilityModule: table, objects: Folder)
    local grenade: Types.Grenade = {
        Caster = abilityModule.caster,
        Behavior = abilityModule.castBehavior,
        Options = Types.GrenadeOptions.new(abilityModule.name, abilityModule),
        Connections = {},
        CurrentGrenadeObject = nil
    }

    grenade.Destroy = function()
        Caster:Remove(Players.LocalPlayer)
        for i, v in pairs(grenade.Connections) do
            v:Disconnect()
        end
    end

    return grenade :: Types.Grenade
end

return grenades
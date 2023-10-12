--[[ Grenades Module

    - Initializes on require
    - Must be required by Client and Server

    - LocalCaster is the stored FastCast Caster that will be used when YOU use a grenade ability.
    - GlobalCaster is the stored FastCast Caster that will be used when OTHER PLAYERS use a grenade ability.

]]

export type Grenade = {
    LocalCaster: table,
    GlobalCaster: table,
    Ability: table, -- The ability's class
}

export type Caster = {
    CastCaster: table,
    CastBehavior: table
}

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local FastCast = require(Framework.Module.lib.c_fastcast)

local Grenades = {}

function Grenades.init()
    Grenades.Local = {}
    Grenades.Global = {}

    for _, v in pairs(Framework.Service.AbilityService.Ability:GetChildren()) do
        local _req = require(v)
        if _req.Configuration.isGrenade then
            _req.Options = _req.Configuration
            local grenade = {
                LocalCaster = false,
                GlobalCaster = false,
                Ability = _req
            }

            grenade.LocalCaster = {
                CastCaster = FastCast.new(),
                CastBehavior = FastCast.newBehavior()
            }
        end
    end
end

function Grenades.CreateLocalCaster()
    
end

function Grenades.CreateGlobalCaster()
    
end

return Grenades
--[[
    Module responsible for handling movement restrictions and penalties.

    ie: weapons that will slow a player when equipped, which a player has an inventory of.
    if the player needs to cycle weapons, we dont want the movement penalty to be added on twice or vice versa.

]]


local restrictions = {}

--[[local Movement = {}
local MovementRestrictions = {}

function restrictions.Init(movement)
    restrictions.movementOptions = movement
    Movement = {
        CurrentRestriction = "Run",
        GroundSpeed = movement.groundMaxSpeed,
        GroundAcceleration = movement.groundAccelerate,
        Friction = movement.friction
    }
    MovementRestrictions = {
        Crouch = {
            GroundSpeed = movement.crouchMoveSpeed,
            GroundAcceleration = movement.crouchAccelerate,
            Friction = movement.crouchFriction
        },
        Walk = {
            GroundSpeed = movement.walkMoveSpeed,
            GroundAcceleration = movement.walkAccelerate,
            Friction = movement.crouchFriction
        },
        Run = {
            GroundSpeed = Movement.GroundSpeed,
            GroundAcceleration = Movement.GroundAcceleration,
            Friction = Movement.Friction
        }
    }
end

function Movement.SetCurrentRestriction(r)
    if MovementRestrictions[r] then
        for i, v in pairs(MovementRestrictions[r]) do
            Movement[i] = v
        end
        Movement.CurrentRestriction = r
    end
end

function Movement.GetCurrentRestriction()
    return Movement.CurrentRestriction
end]]

-- Weapon Restrictions

local Weapon = {
    CurrentlyEquippedWeapon = "None",
    SpeedSubtract = 0,
}

function restrictions:SetWeaponRestriction(r, weaponOptions)
    
end

return restrictions
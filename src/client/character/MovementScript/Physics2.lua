local Math = require(game:GetService("ReplicatedStorage"):WaitForChild("lib").fc_math)

local Physics = {}

function ApplyFriction()
    
end

function Accelerate()
    
end

function CalculateMovementVelocity(self, groundNormal)
    local fric = self.crouching and self.crouchFriction or self.friction
    local accel = self.crouching and self.crouchAcceleration or self.groundAcceleration
    local decel = self.crouching and self.crouchDeceleration or self.groundDeceleration

    local forward = groundNormal:Cross(self.collider.CFrame.RightVector)
	local right = groundNormal:Cross(forward)

    local speed = self.crouching and self.crouchSpeed or self.groundMaxSpeed
    speed = self.walking and self.walkSpeed or speed

    local _wishDir

    ApplyFriction(fric, true, true)

    local forwardMove = self.currentInputSum.Forward
    local rightMove = self.currentInputSum.Side

    _wishDir = forwardMove * forward + rightMove * right
    _wishDir = _wishDir.Unit

    local forwardVelocity = groundNormal:Cross(CFrame.fromAxisAngle(-90, Vector3.new(0,1,0) * Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z)))

    --Set the target speed of the player
    local _wishSpeed = _wishDir.Magnitude
    _wishSpeed *= speed

    --Accelerate
    local yVel = self.movementVelocity.Velocity.Y
    Accelerate(_wishDir, _wishSpeed, accel * 1, false)

    local maxVelocityMagnitude = self.maxVelocity
    self.movementVelocity.Velocity = Math.fixedVector3Clamp(Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z), -maxVelocityMagnitude, maxVelocityMagnitude)
    self.movementVelocity.Velocity.Y = yVel

    -- Calculate how much slopes should affect movement
    local yVelNew = forwardVelocity.Unit.Y * Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z).Magnitude

    -- Apply the Y-movement from slopes
    self.movementVelocity.Velocity.Y = yVelNew * (_wishDir.y < 0 and 1.2 or 1.0)
end

return Physics
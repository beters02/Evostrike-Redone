--[[private void LadderPhysics () {
            
    _surfer.moveData.ladderVelocity = _surfer.moveData.ladderClimbDir * _surfer.moveData.verticalAxis * 6f;

    _surfer.moveData.velocity = Vector3.Lerp (_surfer.moveData.velocity, _surfer.moveData.ladderVelocity, Time.deltaTime * 10f);

    LadderCheck (Vector3.one, _surfer.moveData.ladderDirection);
    
    Trace floorTrace = TraceToFloor ();
    if (_surfer.moveData.verticalAxis < 0f && floorTrace.hitCollider != null && Vector3.Angle (Vector3.up, floorTrace.planeNormal) <= _surfer.moveData.slopeLimit) {
        _surfer.moveData.velocity = _surfer.moveData.ladderNormal * 0.5f;
        _surfer.moveData.ladderVelocity = Vector3.zero;
        _surfer.moveData.climbingLadder = false;
    }

    if (_surfer.moveData.wishJump) {
        _surfer.moveData.velocity = _surfer.moveData.ladderNormal * 4f;
        _surfer.moveData.ladderVelocity = Vector3.zero;
        _surfer.moveData.climbingLadder = false;
    }
    
}]]

local UP = Vector3.new(0,1,0)
local TEMP_ANGLED_LADDERS_ENABLED = true
local TEMP_BOXCAST_SIZE = Vector3.new(0.3,0.2,0.3)
local TEMP_LADDER_SPEED = 12

function transformAngle(vec: Vector3, amnt: Vector3)
    return vec * CFrame.Angles(amnt.X, amnt.Y, amnt.Z).LookVector
end

function upRot()
    return Vector3.new(0,math.rad(-90),0)
end

local Ladder = {}

function Ladder:Check()
    if self.movementVelocity.Velocity.Magnitude <= 2 then
        return
    end

    if self.ladderCancel then
        local t = tick()
        if t - .6 >= self.ladderCancel then
            self.ladderCancel = false
        else
            return
        end
    end

    --local player = game.Players.LocalPlayer
    local direction = self.collider.CFrame.LookVector
    --local cf = self.collider.Parent.RightUpperLeg.CFrame
    --local direction = cf.LookVector

    --local hit = workspace:Blockcast(CFrame.new(self.collider.CFrame.Position), TEMP_BOXCAST_SIZE, direction, self.LadderParams)
    local hit = false
    local hitOrigin
    for _, v in pairs({Vector3.zero, Vector3.new(0,-2,0), Vector3.new(0, -4, 0), Vector3.new(0, -6, 0), Vector3.new(0, 2, 0), Vector3.new(0,4,0)}) do
        local _hit = workspace:Blockcast(CFrame.new(self.collider.CFrame.Position + v), TEMP_BOXCAST_SIZE, direction, self.LadderParams)
        if _hit then
            local result = workspace:Raycast(v, direction * _hit.Distance, self.LadderParams)
            if result and result.Instance.CollisionGroup ~= "Ladders" then
                hit = false
                break
            end

            hit = _hit
            hitOrigin = self.collider.CFrame.Position + v
        end
    end

    if hit then
        local result = workspace:Raycast(hitOrigin, direction * 5, self.LadderParams)
        if result and result.Instance.CollisionGroup ~= "Ladders" then
            hit = false
        end
    end

    if not hit then
        self.ladderNormal = Vector3.zero
        self.ladderVelocity = Vector3.zero
        self.laddering = false
        self.ladderClimbDir = UP
        --print('ladder not found')
        return false
    end

    if not self.laddering then
        self.laddering = true
        self.ladderNormal = hit.Normal
        self.ladderDirection = -hit.Normal * direction.Magnitude * 2

        if TEMP_ANGLED_LADDERS_ENABLED then
            local sideDir = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
            sideDir = transformAngle(sideDir, upRot())
            self.ladderClimbDir = transformAngle(sideDir, upRot()) * hit.Normal
            if self.ladderClimbDir.Magnitude == 0 then
                self.ladderClimbDir = Vector3.new(0,1,0)
            else
                self.ladderClimbDir = self.ladderClimbDir.Magnitude * Vector3.new(0,1,0)
            end
            self.ladderClimbDir *= 1 / self.ladderClimbDir.Y
        else
            self.ladderClimbDir = Vector3.new(0,1,0)
        end
    end

    return true
end

function Ladder:Physics()
    self.grounded = false
    self.ladderVelocity = self.ladderClimbDir * self.currentInputSum.Forward * TEMP_LADDER_SPEED

    --self.collider.Velocity = self.collider.Velocity:Lerp(self.ladderVelocity, self.currentDT * 10)
    local newVel = self.movementVelocity.Velocity:Lerp(self.ladderVelocity, self.currentDT * 10)
    self.movementVelocity.Velocity = newVel
    self.collider.Velocity = Vector3.new(self.collider.Velocity.X, newVel.Y, self.collider.Velocity.Z)
    self.ladderLerpVelocity = newVel

    Ladder.Check(self)

    if not self.laddering then
        --self.movementVelocity.Velocity = self.ladderNormal * 0.5
        --self.collider.Velocity = self.ladderNormal * 0.5
        self.ladderVelocity = Vector3.zero
    end

    if self.jumping then
        --self.collider.Velocity = self.ladderNormal * 4
        --self.movementVelocity.Velocity = self.ladderNormal * 4
        self.ladderVelocity = Vector3.zero
        self.laddering = false
        self.ladderCancel = tick()
    end
end

return Ladder

--[[
    private void LadderCheck (Vector3 colliderScale, Vector3 direction) {

            if (_surfer.moveData.velocity.sqrMagnitude <= 0f)
                return;
            
            bool foundLadder = false;

            RaycastHit [] hits = Physics.BoxCastAll (_surfer.moveData.origin, Vector3.Scale (_surfer.collider.bounds.size * 0.5f, colliderScale), Vector3.Scale (direction, new Vector3 (1f, 0f, 1f)), Quaternion.identity, direction.magnitude, SurfPhysics.groundLayerMask, QueryTriggerInteraction.Collide);
            foreach (RaycastHit hit in hits) {

                Ladder ladder = hit.transform.GetComponentInParent<Ladder> ();
                if (ladder != null) {

                    bool allowClimb = true;
                    float ladderAngle = Vector3.Angle (Vector3.up, hit.normal);
                    if (_surfer.moveData.angledLaddersEnabled) {

                        if (hit.normal.y < 0f)
                            allowClimb = false;
                        else {
                            
                            if (ladderAngle <= _surfer.moveData.slopeLimit)
                                allowClimb = false;

                        }

                    } else if (hit.normal.y != 0f)
                        allowClimb = false;

                    if (allowClimb) {
                        foundLadder = true;
                        if (_surfer.moveData.climbingLadder == false) {

                            _surfer.moveData.climbingLadder = true;
                            _surfer.moveData.ladderNormal = hit.normal;
                            _surfer.moveData.ladderDirection = -hit.normal * direction.magnitude * 2f;

                            if (_surfer.moveData.angledLaddersEnabled) {

                                Vector3 sideDir = hit.normal;
                                sideDir.y = 0f;
                                sideDir = Quaternion.AngleAxis (-90f, Vector3.up) * sideDir;

                                _surfer.moveData.ladderClimbDir = Quaternion.AngleAxis (90f, sideDir) * hit.normal;
                                _surfer.moveData.ladderClimbDir *= 1f/ _surfer.moveData.ladderClimbDir.y; // Make sure Y is always 1

                            } else
                                _surfer.moveData.ladderClimbDir = Vector3.up;
                            
                        }
                        
                    }

                }

            }

            if (!foundLadder) {
                
                _surfer.moveData.ladderNormal = Vector3.zero;
                _surfer.moveData.ladderVelocity = Vector3.zero;
                _surfer.moveData.climbingLadder = false;
                _surfer.moveData.ladderClimbDir = Vector3.up;

            }

        }
]]
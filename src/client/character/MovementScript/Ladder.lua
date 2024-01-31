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
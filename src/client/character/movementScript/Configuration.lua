local module = {

	--[[ General Settings ]]
	gravity = .25,
	friction = 7,
	maxVelocity = 50,
	maxMovementPitch = 0.6,

	--[[ Ground Settings ]]
	groundAccelerate = 8,
	groundDeccelerate = 10, -- the lower this number is, the longer it takes to decel btw
	groundMaxSpeed = 21,

	--[[ Air Settings ]]
	airAccelerate = 22,
	airSpeed = 5,
	airMaxSpeed = 33,
	airMaxSpeedFriction = 4,
	airMaxSpeedFrictionDecrease = 0.2,

	--[[ Jump Settings ]]
	jumpVelocity = 29,
	jumpTimeBeforeGroundRegister = 0.1,

	--[[ Land Settings ]]
	minInAirTimeRegisterLand = 0.3,
	landingMovementDecreaseLength = 0.24,
	landingMovementDecreaseFriction = 1.4,

	--[[ Bhop Settings ]]
	missedBhopDecrease = 0.4,
	autoBunnyHop = false,

	--[[ Character Settings ]]
	playerTorsoToGround = 5,
	movementStickDistance = 0.85

}

return module
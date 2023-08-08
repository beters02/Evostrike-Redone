local module = {

	--[[ General Settings ]]
	gravity = .25,
	friction = 6,
	maxVelocity = 50,
	maxMovementPitch = 0.6,

	--[[ Ground Settings ]]
	groundAccelerate = 8,
	groundDeccelerate = 8,
	groundMaxSpeed = 22,

	--[[ Air Settings ]]
	airAccelerate = 45,
	airSpeed = 5,
	airMaxSpeed = 31,
	airMaxSpeedFriction = 3.5,

	--[[ Jump Settings ]]
	jumpVelocity = 29,
	jumpTimeBeforeGroundRegister = 0.1,

	--[[ Land Settings ]]
	minInAirTimeRegisterLand = 0.3,
	landingMovementDecrease = 0.8,
	landingMovementDecreaseLength = 0.15,

	--[[ Bhop Settings ]]
	missedBhopDecrease = 0.4,
	autoBunnyHop = false,

	--[[ Character Settings ]]
	playerTorsoToGround = 5,
	movementStickDistance = 0.85

}

return module
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local InitSprayPattern = require(Framework.shfc_initSprayPattern.Location)

local module = {
	inventorySlot = "ternary",
	
	totalAmmoSize = 90,
	magazineSize = 30,
	
	equipLength = 1,
	fireRate = 0.155,
	reloadLength = 1.5,
	recoilReset = 0.3,
	
	fireVectorCameraOffset = Vector2.new(10, 10),
	fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1),
	
	fireVectorSpring = {
		speed = 50,
		damp = 1,
		downWait = 0.07,
		max = 0.1
	},
	
	accuracy = {
		firstBullet = true,
		base = 3,
		spray = 2,
		walk = 10,
		run = 15,
		jump = 120
	},
	
	damage = {
		base = 26,
		headMultiplier = 5,
		legMultiplier = 0.9,
		damageFalloffPerMeter = 1.5,
		damageFalloffDistance = 20,
		damageFalloffMinimumDamage = 20,
		enableHeadFalloff = false
	},

	movement = {
		penalty = 0,
		hitTagAmount = 6
	}
	
}

module.sprayPattern = "Melee"

return module
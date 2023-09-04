local wepconfig = {
	inventorySlot = "secondary",
	automatic = false,
	
	equipLength = 0.8,
	fireRate = 0.15,
	reloadLength = 1,
	recoilReset = 0.35,
	
	fireVectorCameraOffset = Vector2.new(5, 5), -- Side, Up
	fireAccuracyCameraOffset = Vector2.new(5, 5), -- Side, Up
	fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1), -- Up, Side
	
	ammo = {
		magazine = 15,
		total = 60
	},
	
	accuracy = {
		firstBullet = 5,
		base = 18,
		spray = 2,
		walk = 22,
		run = 25,
		jump = 120,
		spread = true
	},
	
	damage = {
		base = 15,
		min = 10,

		headMultiplier = 3.3,
		legMultiplier = 0.9,
		damageFalloffPerMeter = 1.5,
		damageFalloffDistance = 20,
		enableHeadFalloff = true,
		headFalloffMultiplier = 0.6, -- Multiplier applied to damage falloff per meter
	},

	movement = {
		penalty = 2.2,
		hitTagAmount = 6
	},

	serverModelSize = 0.75
	
}

wepconfig.damage.damageFalloffMinimumDamage = wepconfig.damage.min

local sprayPattern = require(game:GetService("ServerScriptService"):WaitForChild("weapon"):WaitForChild("config"):WaitForChild("glock17"):WaitForChild("spraypattern"))
wepconfig.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.spread)

return wepconfig
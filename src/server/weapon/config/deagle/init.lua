local wepconfig = {
	inventorySlot = "secondary",
	automatic = false,
	
	equipLength = 1,
	fireRate = 0.16,
	reloadLength = 1.5,
	recoilReset = 0.5,
	
	fireVectorCameraOffset = Vector2.new(5, 5), -- Side, Up
	fireAccuracyCameraOffset = Vector2.new(5, 5), -- Side, Up
	fireVectorCameraMax = Vector3.new(0.01, 0.008, 0.1), -- Up, Side
	
	ammo = {
		magazine = 15,
		total = 60
	},
	
	accuracy = {
		firstBullet = 5,
		base = 25,
		spray = 2,
		walk = 130,
		run = 130,
		jump = 120,
		spread = true
	},
	
	damage = {
		base = 55,
		min = 42,

		headMultiplier = 3.3,
		legMultiplier = 0.9,
		damageFalloffPerMeter = 0.8,
		damageFalloffDistance = 27,
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
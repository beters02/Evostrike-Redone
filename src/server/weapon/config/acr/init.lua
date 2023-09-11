local wepconfig = {
    inventorySlot = "primary",
	automatic = true,
	
	equipLength = 1,
	fireRate = 0.0909, -- 660 rpm
	reloadLength = 1.5,
	recoilReset = 0.22,
	camRecoilReset = 0.5,
	
	fireVectorCameraOffset = Vector2.new(5, 13), -- Side, Up
	fireAccuracyCameraOffset = Vector2.new(1, 10), -- Side, Up
	fireVectorCameraMax = Vector3.new(0.009, 0.0101, 0.3), -- Up, Side
	
	ammo = {
		magazine = 25,
		total = 100
	},
	
	accuracy = {
		firstBullet = 2,
		base = 5,
		walk = 190,
		run = 190,
		jump = 150
	},
	
	damage = {
		base = 23,
		headMultiplier = 4,
		legMultiplier = 0.9,
		damageFalloffPerMeter = 0.7,
		damageFalloffDistance = 35,
		damageFalloffMinimumDamage = 19,
		enableHeadFalloff = false
	},
	
	movement = {
		penalty = 2.6,
		hitTagAmount = 6
	},

	serverModelSize = 0.75
}

local sprayPattern = require(game:GetService("ServerScriptService"):WaitForChild("weapon"):WaitForChild("config"):WaitForChild("ak103"):WaitForChild("spraypattern"))
wepconfig.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.vec)

return wepconfig
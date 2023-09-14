local wepconfig = {
	name = "ak103",
    inventorySlot = "primary",
	automatic = true,
	
	equipLength = 1,
	fireRate = 0.1, -- 600 rpm
	reloadLength = 1.5,
	recoilReset = 0.24,
	camRecoilReset = 0.5,
	
	fireVectorCameraOffset = Vector2.new(5, 13), -- Side, Up
	fireAccuracyCameraOffset = Vector2.new(1, 10), -- Side, Up
	fireVectorCameraMax = Vector3.new(0.011, 0.01, 0.3), -- Up, Side
	
	ammo = {
		magazine = 30,
		total = 90
	},
	
	accuracy = {
		firstBullet = 2,
		base = 7,
		walk = 200,
		run = 200,
		jump = 150
	},
	
	damage = {
		base = 26,
		headMultiplier = 5,
		legMultiplier = 0.9,
		damageFalloffPerMeter = 0.7,
		damageFalloffDistance = 40,
		damageFalloffMinimumDamage = 20,
		enableHeadFalloff = false,
		helmetMultiplier = 1,
		destroysHelmet = true,
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
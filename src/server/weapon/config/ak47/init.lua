local wepconfig = {
    inventorySlot = "primary",
	automatic = true,
	
	totalAmmoSize = 90,
	magazineSize = 30,
	
	equipLength = 1,
	fireRate = 0.105, -- 0.118
	reloadLength = 1.5,
	recoilReset = 0.24,
	camRecoilReset = 0.5,
	
	fireVectorCameraOffset = Vector2.new(10, 35),
	fireVectorCameraMax = Vector3.new(0.009, 0.011, 0.3),
	
	ammo = {
		magazine = 30,
		total = 90
	},
	
	accuracy = {
		firstBullet = true,
		base = 5,
		spray = 2,
		walk = 90,
		run = 100,
		jump = 150
	},
	
	damage = {
		base = 26,
		headMultiplier = 5,
		legMultiplier = 0.9,
		damageFalloffPerMeter = 0.7,
		damageFalloffDistance = 50,
		damageFalloffMinimumDamage = 20,
		enableHeadFalloff = false
	},
	
	serverModelSize = 0.75
}

local sprayPattern = require(game:GetService("ServerScriptService"):WaitForChild("weapon"):WaitForChild("config"):WaitForChild("ak47"):WaitForChild("spraypattern"))
wepconfig.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.vec)

return wepconfig
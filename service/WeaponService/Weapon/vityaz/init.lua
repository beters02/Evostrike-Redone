local wepconfig = {
	Configuration = {
		name = "vityaz",
		inventorySlot = "primary",
		automatic = true,
		
		equipLength = 1,
		fireRate = 0.115, -- 0.118
		reloadLength = 1.4,
		recoilReset = 0.2,
		camRecoilReset = 0.5,
		
		fireVectorCameraOffset = Vector2.new(5, 12), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(1, 10), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.011, 0.01, 0.3), -- Up, Side
		
		ammo = {
			magazine = 25,
			total = 100
		},
		
		accuracy = {
			firstBullet = 4,
			base = 10,
			walk = 97,
			run = 100,
			jump = 150
		},
		
		damage = {
			base = 33,
			min = 25,

			headMultiplier = 4.8,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 0.7,
			damageFalloffDistance = 50,
			damageFalloffMinimumDamage = 20,
			enableHeadFalloff = false,
			helmetMultiplier = 0.7,
			destroysHelmet = true,
		},
		
		movement = {
			penalty = 2.6,
			hitTagAmount = 6
		},

		serverModelSize = 0.75
	}
}

local sprayPattern = require(script:WaitForChild("spraypattern"))
wepconfig.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.vec)

return wepconfig
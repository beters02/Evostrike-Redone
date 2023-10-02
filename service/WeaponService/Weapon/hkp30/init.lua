local wepconfig = {
	Configuration = {
		name = "hkp30",
		inventorySlot = "secondary",
		automatic = false,
		
		equipLength = 1,
		fireRate = 0.16,
		reloadLength = 1,
		recoilReset = 0.35,
		
		fireVectorCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(5, 5), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1), -- Up, Side
		
		ammo = {
			magazine = 12,
			total = 24
		},
		
		accuracy = {
			firstBullet = 2,
			base = 18,
			crouch = 2,
			spray = 2,
			walk = 25,
			run = 30,
			jump = 120,
			spread = true
		},
		
		damage = {
			base = 22,
			min = 12,

			headMultiplier = 7,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 1.5,
			damageFalloffDistance = 20,
			enableHeadFalloff = false,
			headFalloffMultiplier = 0.6, -- Multiplier applied to damage falloff per meter
			helmetMultiplier = 0.42,
			destroysHelmet = false,
		},

		movement = {
			penalty = -2.2,
			hitTagAmount = 6
		},

		serverModelSize = 0.75
	}
}

wepconfig.Configuration.damage.damageFalloffMinimumDamage = wepconfig.Configuration.damage.min

local sprayPattern = require(script:WaitForChild("spraypattern"))
wepconfig.Configuration.sprayPattern = require(game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("fc_initSprayPattern"))(sprayPattern.spread)

return wepconfig
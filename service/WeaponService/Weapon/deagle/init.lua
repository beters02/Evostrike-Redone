local wepconfig = {
	Configuration = {
		name = "deagle",
		inventorySlot = "secondary",
		automatic = false,
		
		equipLength = 0.7,
		fireRate = 0.16, -- 375 rpm
		reloadLength = 0.7,
		recoilReset = 0.5,
		
		fireVectorCameraOffset = Vector2.new(10, 10), -- Side, Up
		fireAccuracyCameraOffset = Vector2.new(10, 10), -- Side, Up
		fireVectorCameraMax = Vector3.new(0.017, 0.015, 0.1), -- Up, Side
		
		ammo = {
			magazine = 7,
			total = 21
		},
		
		accuracy = {
			firstBullet = 5,
			base = 35,
			crouch = 35,
			spray = 2,
			walk = 170,
			run = 170,
			jump = 150,
			spread = true
		},
		
		damage = {
			base = 55,
			min = 33,

			headMultiplier = 3.3,
			legMultiplier = 0.9,
			damageFalloffPerMeter = 1,
			damageFalloffDistance = 24,
			enableHeadFalloff = false,
			headFalloffMultiplier = 0.6, -- Multiplier applied to damage falloff per meter
			
			helmetMultiplier = 1,
			destroysHelmet = true,
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
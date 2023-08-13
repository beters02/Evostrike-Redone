local core = {}
core.__index = core

--[[@title 			- core_fire
	@return			- {void}
]]

function core.fire(self, player, weaponOptions, weaponVar, weaponCameraObject, animationEventFunctions)
    local mouse = player:GetMouse()
    -- set var
	local t = tick()
	local mosPos = Vector2.new(mouse.X, mouse.Y)
	local fireRegisterTime = workspace:GetServerTimeNow()
	weaponVar.fireLoop = true
	weaponVar.firing = true
	weaponVar.nextFireTime = t + weaponOptions.fireRate
	weaponVar.ammo.magazine -= 1
	weaponVar.currentBullet = (t - weaponVar.lastFireTime >= weaponOptions.recoilReset and 1 or weaponVar.currentBullet + 1)
	weaponVar.lastFireTime = t
	weaponCameraObject.weaponVar.currentBullet = weaponVar.currentBullet

	self.util_registerFireRayAndCameraRecoil()

	-- play animations
	self.util_playAnimation("client", "Fire")
    weaponVar.animations.server.Fire:Play()
	--if hudChar then weaponVar.animations.clienthud.Fire:Play() end

	-- play sounds
	task.spawn(function()
		animationEventFunctions.PlayReplicatedSound("Fire", true)
	end)
	
	-- handle client fire rate
	task.spawn(function() 
		local nextFire = t + weaponOptions.fireRate
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
	end)
end

--[[@title 			- core_reload
	@return			- {void}
]]

function core.reload(weaponVar, weaponRemoteFunction)
	if weaponVar.ammo.total <= 0 then return end
	if weaponVar.firing or weaponVar.reloading or not weaponVar.equipped then return end
	
	task.spawn(function()
		weaponVar.animations.client.Reload:Play()
		--weaponVar.animations.server.Reload:Play() TODO: make server reload animations
	end)

	weaponVar.reloading = true
	local mag, total = weaponRemoteFunction:InvokeServer("Reload")
	weaponVar.ammo.magazine = mag
	weaponVar.ammo.total = total
	weaponVar.reloading = false
end

return core
--[[function Fire()

	-- set var
	weaponVar.fireLoop = true
	weaponVar.firing = true
	local t = tick()
	weaponVar.nextFireTime = t + weaponOptions.fireRate
	weaponVar.ammo.magazine -= 1
	weaponVar.currentBullet = (t - weaponVar.lastFireTime >= weaponOptions.recoilReset and 1 or weaponVar.currentBullet + 1)
	CameraObject.weaponVar.currentBullet = weaponVar.currentBullet
	weaponVar.lastFireTime = t
	local fireRegisterTime = workspace:GetServerTimeNow()

	local currVecOption, currShakeOption = CameraObject:GetSprayPatternKey()			-- get recoil pattern key
	local currVecRecoil = CameraObject:GetRecoilVector3(currVecOption)				-- convert VectorRecoil or SpreadRecoil key into a Vector3
	--local currShakeRecoil = cameraClass:GetRecoilVector3(currShakeOption)			-- convert ShakeRecoil key into a Vector3
	
	-- init paramaters for client bullet registration

	-- play animations
    weaponVar.animations.client.Fire:Play()
    weaponVar.animations.server.Fire:Play()
	
	task.spawn(function() -- client fire rate
		local nextFire = t + weaponOptions.fireRate
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
	end)
	
	local mosPos = Vector2.new(mouse.X, mouse.Y)
	
	task.spawn(function() -- client accuracy & bullet, fire camera spring
		--[[local clientAcc
		clientAcc, weaponVar = CalculateAccuracy(weaponVar.currentBullet, currVecRecoil, weaponVar)
		local unitRay = GetNewTargetRay(mosPos, clientAcc)]]
		--[[task.spawn(function() -- camera spring is fired after the accuracy is registered, to avoid bullets going in the wrong place.
			CameraObject:FireRecoil(weaponVar.currentBullet)
		end)
		task.spawn(function()
			RegisterFireRay()
			--[[local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 100, params)
			if not result then return end
			WeaponFunctions.RegisterShot(player, weaponOptions, result, unitRay.Origin)
		end)
	end)
	
	--[[task.spawn(function() -- server accuracy
		local serverAcc = weaponRemoteFunction:InvokeServer("GetAccuracy", currVecRecoil, weaponVar.currentBullet, char.HumanoidRootPart.Velocity.Magnitude)
		--print(tostring(serverAcc) .. " server accuracy")
		local finalRay = GetNewTargetRay(mosPos, serverAcc)
		local serverBulletHole = weaponRemoteFunction:InvokeServer("Fire", finalRay, weaponVar.currentBullet, currVecRecoil, fireRegisterTime)
		if serverBulletHole then serverBulletHole:Destroy() end
	end)
end]]
--[[function FireOld(finalRay, currentBullet, recoilVector3, shotRegisteredTime) -- Returns BulletHole
	local diff = serverStoredVar.nextFireTime - tick()
	if diff > 0 then
		if diff > 0.01899 then
			print(tostring(diff) .. " TIME UNTIL NEXT ALLOWED FIRE")
			return
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, workspace.Temp}
	params.CollisionGroup = "Bullets"

	local result = workspace:Raycast(finalRay.Origin, finalRay.Direction * 100, params)

	serverStoredVar.ammo.magazine -= 1
	serverStoredVar.nextFireTime = tick() + weaponOptions.fireRate

	WeaponFunctions.RegisterShot(player, weaponOptions, result, finalRay.Origin, finalRay.Direction, shotRegisteredTime)
end]]

--[[
	[LagCompensation]

local function lagCompensationShotIsRegisteredFromPartPos(player, dir, origin, pos)
	local d = dir.Unit
	local nd = (origin-pos).Unit
	local rd = player.Character.HumanoidRootPart.CFrame:VectorToWorldSpace(CFrame.new(pos):VectorToObjectSpace(-1 * nd))
	if math.abs(d.X - rd.X) < 0.03 or math.abs(d.Z - rd.Z) < 0.03 then
		print('HIT REGISTERED')
		return rd
	end
	print(pos)
	print(d)
	print(nd)
	print(rd)
	local dirDiff = d - nd
	print(dirDiff)
	print(nd - rd)
	return false
end

function module.LagCompensateRegisterShot(player, registerTime, origin, dir, weaponOptions)
	local tickStore = WeaponRemotes.ServerGet:Invoke(player, (registerTime - workspace:GetServerTimeNow()) + player:GetNetworkPing())
	if not tickStore then return end
	-- recieved lc store
	for i, v in pairs(tickStore) do
		print('getting player')
		if v[1] ~= player then
			print('getting part')
			for _, partTable in pairs(v[2]) do
				print(partTable)
				for partName, position in pairs(partTable) do
					local hitNorm = lagCompensationShotIsRegisteredFromPartPos(player, dir, origin, position)
					if hitNorm then
						print(partName)
						getDamageFromHumResult(player, v[1].Character, weaponOptions, position, v[1].Character[partName], hitNorm, origin)
						break
					end
				end
			end
		end
	end
	return false
end
]]
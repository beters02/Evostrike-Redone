--[[local mfunctions = require(char.MovementScript.Functions)
local testStickingOffset = camera.CFrame.Position
local function flatten(cf, modifier)
	local newVec, stickNormals, stickingDirections, lowestDir = mfunctions:ApplyAntiSticking(cf.Position, modifier)
	if not stickNormals then return false end
	local dir
	for i, v in pairs(stickingDirections) do
		if not dir then dir = v continue end
		dir += v
	end

	if not dir then return end

	if lowestDir then dir = lowestDir end

	local min
	local newCF = cf
	local newVec = CFrame.new(-dir.X, -dir.Y, -dir.Z).Position.Unit * Vector3.new(2, 1, 2)

	newCF = (newCF + newVec)

	return newCF
end

local op = OverlapParams.new()
op.FilterType = Enum.RaycastFilterType.Exclude
op.FilterDescendantsInstances = {char, camera}

local function HandleWeaponCollision()
	-- equipped check
	if not equippedWeapon then
		local c = vm.Equipped:GetChildren()
		if #c > 0 then
			equippedWeapon = c[1]
		else
			
			-- DO RIGHT/LEFT HAND CHECK

		end
	end

	if equippedWeapon then
		local collision = workspace:GetPartsInPart(equippedWeapon.GunComponents.WeaponTip, op)
		if #collision > 0 then
			print(collision)
			local f = flatten(hrp.CFrame, 5, true)
			if f then
				hrp.CFrame = f
			end
		end
		
	end
end]]
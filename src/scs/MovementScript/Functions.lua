local module = {}

-- [[ GET ]]

function module:GetPartYRatio(normal)
	local partYawVector = Vector3.new(-normal.x, 0, -normal.z)
	if partYawVector.magnitude == 0 then
		return 0,0
	else
		local partPitch = math.atan2(partYawVector.magnitude,normal.y)/(math.pi/2)
		local vector = Vector3.new(self.cameraLook.x, 0, self.cameraLook.z)*partPitch
		return vector:Dot(partYawVector), -partYawVector:Cross(vector).y
	end	
end

function module.Magnitude2D(x, z)
	return math.sqrt(x*x+z*z)
end

function module:GetCharacterMass()
	return self.collider:GetMass() + self.head:GetMass()
end

function module:GetYaw():CFrame
	return self.camera.CoordinateFrame*CFrame.Angles(-self:GetPitch(),0,0)
end

function module:GetPitch():number
	return math.pi/2 - math.acos(self.camera.CoordinateFrame.lookVector:Dot(Vector3.new(0,1,0)))
end

-- [[ SET ]]

function module:SetCharacterRotation()
	local collider = self.collider
	local camera = self.camera
	local rotationLook = collider.Position + camera.CoordinateFrame.lookVector
	collider.CFrame = CFrame.new(collider.Position, Vector3.new(rotationLook.x, collider.Position.y, rotationLook.z))
	collider.RotVelocity = Vector3.new()
end

--[[
	FindCollisionRay
	
	@return i actually dont exactly know what this returns
	returns feet position collision for 3 directions ?
]]

function module:FindCollisionRay()
	local torsoCFrame = self.character.HumanoidRootPart.CFrame
	local ignoreList = {self.character, self.camera}

	local rays = {
		Ray.new(self.character.HumanoidRootPart.Position, Vector3.new(0, -self.rayYLength, 0)),
		Ray.new((torsoCFrame * CFrame.new(-self.rayXLength,0,0)).p, Vector3.new(0, -self.rayYLength, 0)), -- EPIXPLODE: i changed the ray x distance values from 0.8 to 0.4, this is what makes the stickiness feel better
		Ray.new((torsoCFrame * CFrame.new(self.rayXLength,0,0)).p, Vector3.new(0, -self.rayYLength, 0)),
		Ray.new((torsoCFrame * CFrame.new(0,0,self.rayXLength)).p, Vector3.new(0, -self.rayYLength, 0)),
		Ray.new((torsoCFrame * CFrame.new(0,0,-self.rayXLength)).p, Vector3.new(0, -self.rayYLength, 0))
	}
	local rayReturns = {}

	local i
	for i = 1, #rays do
		local part, position, normal = game.Workspace:FindPartOnRayWithIgnoreList(rays[i],ignoreList)

		if part == nil then
			position = Vector3.new(0,-3000000,0)
		end

		if i == 1 then
			table.insert(rayReturns, {part, position, normal})
		else
			local yPos = position.y
			if yPos <= rayReturns[#rayReturns][2].y then
				table.insert(rayReturns, {part, position, normal})
			else 
				local j
				for j = 1, #rayReturns do
					if yPos >= rayReturns[j][2].y then
						table.insert(rayReturns, j, {part, position, normal})
					end
				end
			end
		end
	end
	i = 1

	local yRatio, zRatio = self:GetPartYRatio(rayReturns[i][3])
	while self.Magnitude2D(yRatio, zRatio) > self.maxMovementPitch and i<#rayReturns do
		i = i + 1
		if rayReturns[i][1] then
			yRatio, zRatio = self:GetPartYRatio(rayReturns[i][3])
		end
	end

	-- CODE INSERTED BY EPIXPLODE
	-- detect front ray for ladders
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {ignoreList}
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ladderResult = workspace:Raycast(torsoCFrame.Position + Vector3.new(0, -1, 0), torsoCFrame.LookVector * 2, params)
	local ladderTable = false
	if ladderResult then
		local model = ladderResult.Instance:FindFirstAncestorWhichIsA("Model")
		if (model and model:GetAttribute("ladder") ~= nil) or string.match(ladderResult.Instance.Name, "Ladder") then
			ladderTable = {ladderResult.Instance, ladderResult.Position, ladderResult.Normal, ladderResult.Distance}
		end
	end

	return rayReturns[i][1], rayReturns[i][2], rayReturns[i][3], yRatio, zRatio, ladderTable
end

--[[
	IsSticking
	
	@return sticking : bool or table - Detects what direction player is sticking in
]]

function module:IsSticking()
	local character = self.character
	local camera = self.camera
	local stickParams = RaycastParams.new()
	stickParams.FilterType = Enum.RaycastFilterType.Exclude
	stickParams.FilterDescendantsInstances = {character, camera}
	local rayOffset = Vector3.new(0, -.65, 0)
	local hrpCF = character.HumanoidRootPart.CFrame
	local hrpPos = hrpCF.Position

	local forwardValues = {hrpCF.LookVector * 1, -hrpCF.LookVector * 1.15}
	local sideValues = {-hrpCF.RightVector * 1.15, hrpCF.RightVector * 1.15}
	local sticking = false

	for i, v in pairs(forwardValues) do
		local result = workspace:Raycast(hrpPos + rayOffset, v, stickParams)
		if result then
			sticking = true
			forwardValues[i] = i == 1 and 1 or -1
			continue
		end
		forwardValues[i] = 0
	end

	for i, v in pairs(sideValues) do
		local result = workspace:Raycast(hrpPos + rayOffset, v, stickParams)
		if result then
			sticking = true
			sideValues[i] = i == 1 and 1 or -1
			continue
		end
		sideValues[i] = 0
	end

	if sticking then
		return {forward = forwardValues, side = sideValues}
	end

	return false
end

return module

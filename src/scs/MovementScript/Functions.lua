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
	local ignoreList = {self.character, self.camera, workspace.Temp}

	local rays = {
		Ray.new(self.character.HumanoidRootPart.Position, Vector3.new(0, -self.rayYLength, 0)),
		Ray.new((torsoCFrame * CFrame.new(-self.rayXLength,0,0)).p, Vector3.new(0, -self.rayYLength, 0)),
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

local function visualizeRayResult(result, origin, direction)
	local position = result and result.Position or (origin + direction)
	local distance = (origin - position).Magnitude
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Size = Vector3.new(0.1, 0.1, distance)
		p.CFrame = CFrame.lookAt(origin, position)*CFrame.new(0, 0, -distance/2)
		p.Parent = workspace.Temp
end

-- flattenVectorAgainstWall: flatten a vector given vector and normal
function flattenVectorAgainstWall(moveVector: Vector3, normal: Vector3)
	-- if magnitudes are 0 then just nevermind
	if moveVector.Magnitude == 0 or normal.Magnitude == 0 then
		return Vector3.zero
	end
	
	-- unit the normal (i its already normalized idk)
	normal = normal.Unit
	
	-- reflect the vector
	local reflected = moveVector - 2 * moveVector:Dot(normal) * normal
	-- add the reflection to the move vector = vector parallel to wall
	local parallel = moveVector + reflected
	
	-- if magnitude 0 NEVERMIND!!!
	if parallel.Magnitude == 0 then
		return Vector3.zero
	end
	
	-- reduce the parallel vector to make sense idk HorseNuggetsXD did all this thank u
	local cropped = parallel.Unit:Dot(moveVector.Unit) * parallel.Unit * moveVector.Magnitude
	return cropped
end

--[[
	Apply AntiSticking

	@param accelDir : Vector3 - The player's wished movement direction

	@return direction : Vector3 - Applys AntiSticking to Acceleration Direction
]]

local VisualizeSticking = false

function module:ApplyAntiSticking(accelDir, inputVec)
	local newDir = accelDir
	local hrp = self.player.Character.HumanoidRootPart

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {self.player.Character, workspace.CurrentCamera, workspace.Temp}

	local rayOffset = Vector3.new(0, -.9, 0)
	local rayPos = hrp.Position + rayOffset

	if math.abs(inputVec.X) > 0.5 then
		accelDir *= 2
	end

	local testDir = Vector3.new(accelDir.X + .9, 0, accelDir.Z).Unit
	local testDir2 = Vector3.new(accelDir.X, 0, accelDir.Z + .9).Unit
	local values = {accelDir, testDir, testDir2}

	local results = {}
	for i, v in pairs(values) do
		local result = workspace:Raycast(rayPos, v, params)
		results[i] = result

		if VisualizeSticking then visualizeRayResult(false, hrp.Position, v) end

		if result then
			return flattenVectorAgainstWall(newDir, result.Normal)
		end
	end

	return newDir
end

return module

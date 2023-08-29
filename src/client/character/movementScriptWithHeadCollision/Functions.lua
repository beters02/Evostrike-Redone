local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Math = require(Framework.shfc_math.Location)
local Workspace = game:GetService("Workspace")
local CastVisuals = require(Framework.shfc_castvisuals.Location)

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

	@summary
	Casts a square plane around the players feet to detect ground collision
	
	@return part, position, normal, yratio, zratio, ladders
]]

-- Pretty sure this is the culprit of the falling through the map type shit
-- We have sphere casts now anyways

function module:FindCollisionRay()
	local torsoCFrame = self.character.HumanoidRootPart.CFrame

	local rays = {
		Ray.new(self.character.HumanoidRootPart.Position, Vector3.new(0, -self.rayYLength, 0)),
		Ray.new((torsoCFrame * CFrame.new(-self.rayXLength,0,0)).p, Vector3.new(0, -self.rayYLength, 0)),
		Ray.new((torsoCFrame * CFrame.new(self.rayXLength,0,0)).p, Vector3.new(0, -self.rayYLength, 0)),
		Ray.new((torsoCFrame * CFrame.new(0,0,self.rayXLength)).p, Vector3.new(0, -self.rayYLength, 0)),
		Ray.new((torsoCFrame * CFrame.new(0,0,-self.rayXLength)).p, Vector3.new(0, -self.rayYLength, 0))
	}
	local rayReturns = {}

	local _params = RaycastParams.new()
	_params.CollisionGroup = "PlayerMovement"
	_params.FilterType = Enum.RaycastFilterType.Exclude
	_params.FilterDescendantsInstances = {self.player.Character, workspace.CurrentCamera}

	for i = 1, #rays do
		local result = workspace:Raycast(rays[i].Origin, rays[i].Direction, _params)
		local part, position, normal

		if not result then
			position = Vector3.new(0,-3000000,0)
			normal = Vector3.zero
		else
			part, position, normal = result.Instance, result.Position, result.Normal
		end

		--local part, position, normal = game.Workspace:FindPartOnRayWithIgnoreList(rays[i], self.GetIgnoreDescendantInstances(self.player))
		--[[if part == nil then
			position = Vector3.new(0,-3000000,0)
		end]]


		-- idk what any of this does
		-- looks like it steps the player up/down which
		-- could be the cause of super jumping
		if i == 1 then
			table.insert(rayReturns, {part, position, normal})
		else
			local yPos = position.y
			if yPos <= rayReturns[#rayReturns][2].y then
				table.insert(rayReturns, {part, position, normal})
			else
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

	-- detect front ray for ladders
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = self.GetIgnoreDescendantInstances(self.player)
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

local currentVisualize = {}

--[[
	@title 							- visulizeRayResult
	@summary						- Visualize a collision ray

	@param result: RaycastResult	- Colliding result
	@param origin: Vector3			- Origin of Raycast
	@param direction: Vector3		- Direction of Raycast

	@return part: BasePart 			- Rays visualized part
]]

local function visualizeRayResult(result, origin, direction)
	local position = result and result.Position or (origin + direction)
	local distance = (origin - position).Magnitude
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(0.1, 0.1, distance)
	p.CFrame = CFrame.lookAt(origin, position)*CFrame.new(0, 0, -distance/2)
	p.Parent = workspace.Temp
	return p
end

--[[
	@title 						- flattenVectorAgainstWall
	@summary					- Flattens a given speed vector on a wall.
	@credit						- Roblox Devforums

	@param moveVector: Vector3  - Wished speed of moving player
	@param normal: Vector3		- Normal of colliding wall

	@return newSpeed: Vector3 	- Updated speed after getting direction from self.currentInputVec
]]

function flattenVectorAgainstWall(moveVector: Vector3, normal: Vector3)
	-- if magnitudes are 0 then just nevermind
	if moveVector.Magnitude == 0 and normal.Magnitude == 0 then
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
	@title 						- ApplyAntiSticking
	@summary					- Applies AntiSticking properties to the given direction.

	@param wishedSpeed: Vector3 	- Wished speed of moving player

	@return newSpeed: Vector3 	- Updated speed after getting direction from self.currentInputVec
]]

local VisualizeSticking = false

function module:ApplyAntiSticking(wishedSpeed, inAir, addSpeed)

	local mod = 1
	
	-- apply antisticking on collider y velocity
	local _wishedSpeed = Vector3.new(0, self.collider.Velocity.Y, 0)
	wishedSpeed = Vector3.new(wishedSpeed.X, _wishedSpeed.Y/2, wishedSpeed.Z)

	if wishedSpeed.Magnitude == 0 then
		if wishedSpeed.Magnitude == 0 then return wishedSpeed end
	end

	-- get input vector
	local inputVec = self.currentInputVec
	local initialinputvec = true
	if not inputVec then
		initialinputvec = false
		--inputVec = {X = 0, Z = 1}
		inputVec = wishedSpeed.Unit
	end

	local newSpeed = wishedSpeed
	local hrp = self.player.Character.HumanoidRootPart

	-- raycast var
	local params = RaycastParams.new()
	params.CollisionGroup = "PlayerMovement"
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = self.GetIgnoreDescendantInstances(self.player)
	local rayOffset = Vector3.new(0, -.9, 0) -- y offset

	-- wished speed modifier
	wishedSpeed *= 2

	-- direction amount var
	local dirAmnt = 1.375 * (mod or 1)
	local mainDirAmnt = 1.55 * (mod or 1)

	-- stick var
	local isSticking = false
	local normals = {}
	local stickingDirections = {}
	local ldd = {dir = false, dist = false} -- lowest distance direction

	-- destroy sticking visualizations
	if VisualizeSticking then
		for i, v in pairs(currentVisualize) do
			v:Destroy()
		end
	end

	-- 3 == Up Dir
	for index, v in pairs({Vector3.new(0, -3.1, 0), Vector3.new(0, 1.5, 0), Vector3.new(0, 2, 0)}) do
		local currForDir
		local currSideDir
		local dontAddFor = false
		local values = {}
		local hval = {}
		local rayPos = hrp.Position + v

		if index == 3 then
			if VisualizeSticking then table.insert(currentVisualize, visualizeRayResult(false, self.player.Character.Head.CFrame.Position - Vector3.new(0, 1, 0), v)) end
			local result = workspace:Raycast(self.player.Character.Head.CFrame.Position - Vector3.new(0, 1, 0), v, params)
			if result then
				newSpeed = flattenVectorAgainstWall(newSpeed, result.Normal)
				self.movementVelocity.Velocity = newSpeed
				if initialinputvec then
					self.collider.Velocity = self.movementVelocity.Velocity
				end
			end
		end

		-- right, front, back
		if inputVec.X > 0 then
			currForDir = hrp.CFrame.RightVector
			table.insert(values, currForDir)
			table.insert(hval, hrp.CFrame.LookVector * dirAmnt)
			table.insert(hval, -hrp.CFrame.LookVector * dirAmnt)
		
		-- left, front, back
		elseif inputVec.X < 0 then
			currForDir = -hrp.CFrame.RightVector
			table.insert(values, currForDir)
			table.insert(hval, hrp.CFrame.LookVector * dirAmnt)
			table.insert(hval, -hrp.CFrame.LookVector * dirAmnt)
		end
		
		-- back, left, right
		if inputVec.Z > 0 then
			dontAddFor = true
			currSideDir = -hrp.CFrame.LookVector
			table.insert(values, currSideDir)
			table.insert(hval, hrp.CFrame.RightVector * dirAmnt)
			table.insert(hval, -hrp.CFrame.RightVector * dirAmnt)

		-- front, left, right
		elseif inputVec.Z < 0 then
			currSideDir = hrp.CFrame.LookVector
			table.insert(values, currSideDir)
			table.insert(hval, hrp.CFrame.RightVector * dirAmnt)
			table.insert(hval, -hrp.CFrame.RightVector * dirAmnt)
		end

		if inputVec.Z == 0 and inputVec.X == 0 then
			values[1] = wishedSpeed.Unit
			table.insert(hval, CFrame.new(wishedSpeed.Unit).RightVector * dirAmnt)
			table.insert(hval, -CFrame.new(wishedSpeed.Unit).RightVector * dirAmnt)
		end
		
		-- middle directions
		if currForDir and currSideDir then
			for i, v in pairs(values) do
				values[i] = v * mainDirAmnt
			end
			table.insert(values, (currForDir+currSideDir) * mainDirAmnt)
		else
			values[1] *= mainDirAmnt
			table.insert(values, (values[1] + hval[1]).Unit * mainDirAmnt)
			table.insert(values, (values[1] + hval[2]).Unit * mainDirAmnt)
			table.insert(values, hval[1])
			table.insert(values, hval[2])
		end

		local partsAlreadyHit = {}

		for a, b in pairs(values) do
			if not b then continue end

			-- visualize ray using pos and direction
			if VisualizeSticking then table.insert(currentVisualize, visualizeRayResult(false, rayPos, b)) end
			
			local result = workspace:Raycast(rayPos, b, params)
			if not result then continue end

			if (not ldd.dir or not ldd.dist) or (ldd.dist and ldd.dist < result.Distance) then
				ldd.dir = b
				ldd.dist = result.Distance
			end

			-- don't collide with the same part twice
			if table.find(partsAlreadyHit, result.Instance) then continue end
			table.insert(partsAlreadyHit, result.Instance)

			-- get the movement direction compared to the wall
			local _v =  newSpeed.Unit * result.Normal
			
			-- find active coordinate of comparison
			for _, c in pairs({_v.X, _v.Y, _v.Z}) do
				if math.abs(c) > 0 then
					_v = c
					break
				end
			end

			-- if we are moving AWAY from the normal, (positive)
			-- then do not flatten the vector.

			-- it's not necessary.
			-- you will stick.
			-- stick.

			if type(_v) == "number" and _v > 0 then
				continue
			end

			if not isSticking then isSticking = true end
			newSpeed = flattenVectorAgainstWall(newSpeed, result.Normal)
			--newSpeed -= result.Instance.Velocity

			self.movementVelocity.Velocity = newSpeed

			if inAir and inputVec.X == 0 and inputVec.Z == 0 then
				self.collider.Velocity = Vector3.new(self.movementVelocity.Velocity.X, 0, self.movementVelocity.Velocity.Z)
			end
		
		end
	end

	return newSpeed, isSticking and normals, isSticking and stickingDirections, isSticking and ldd.dir
end

--[[
	@title 						- ApplyAntiSticking2
	@summary					- Updated AntiSticking using SphereCasts and attempting to resolve the game breaking dash issue.

	@param wishedSpeed: Vector3 	- Wished speed of moving player

	@return newSpeed: Vector3 	- Updated speed after getting direction from self.currentInputVec
]]

--[[local CastVisual = CastVisuals.new(Color3.new(1,0,0), workspace)
function module:ApplyAntiSticking(wishedSpeed, mod, wc)

	if wishedSpeed.Magnitude == 0 then
		return wishedSpeed
	end

	local newSpeed = wishedSpeed
	local hrp = self.player.Character.HumanoidRootPart

	-- raycast var
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = self.GetIgnoreDescendantInstances(self.player)

	local result
	local _castelements
	local hitparts = {}
	local castdirs

	-- then, cast movement direction
	castdirs = {
		newSpeed.Unit,
		(newSpeed.Unit + CFrame.new(newSpeed.Unit).RightVector)/2,
		(newSpeed.Unit + -CFrame.new(newSpeed.Unit).RightVector)/2
	}

	for i, v in pairs(castdirs) do
		_castelements = table.pack(hrp.Parent.Head.CFrame.Position, 2, v, params)
		result = workspace:Spherecast(table.unpack(_castelements))
		if result and not table.find(hitparts, result.Instance) then

			-- sticking visualizations
			if VisualizeSticking then
				CastVisual:Spherecast(table.unpack(_castelements))
			end

			self.movementVelocity.Velocity = flattenVectorAgainstWall(newSpeed, result.Normal)

		end

		_castelements = table.pack(hrp.Parent.Head.CFrame.Position - Vector3.new(0, 4.7, 0), 2, v, params)
		result = workspace:Spherecast(table.unpack(_castelements))
		if result and not table.find(hitparts, result.Instance) then

			-- sticking visualizations
			if VisualizeSticking then
				CastVisual:Spherecast(table.unpack(_castelements))
			end

			newSpeed = flattenVectorAgainstWall(newSpeed, result.Normal)

		end
	end

	if result then return newSpeed end

	-- we cast input direction
	local inputVec = self.currentInputVec
	if not inputVec and wc then inputVec = {X = 0, Z = 1} end

	castdirs = {
		inputVec,
		(inputVec + CFrame.new(inputVec).RightVector)/2,
		(inputVec + -CFrame.new(inputVec).RightVector)/2
	}

	for i, v in pairs(castdirs) do
		_castelements = table.pack(hrp.Parent.Head.CFrame.Position, 2, v, params)
		result = workspace:Spherecast(table.unpack(_castelements))
		if result and not table.find(hitparts, result.Instance) then

			-- sticking visualizations
			if VisualizeSticking then
				CastVisual:Spherecast(table.unpack(_castelements))
			end

			newSpeed = flattenVectorAgainstWall(newSpeed, result.Normal)

		end

		_castelements = table.pack(hrp.Parent.Head.CFrame.Position - Vector3.new(0, 5, 0), 2, v, params)
		result = workspace:Spherecast(table.unpack(_castelements))
		if result and not table.find(hitparts, result.Instance) then

			-- sticking visualizations
			if VisualizeSticking then
				CastVisual:Spherecast(table.unpack(_castelements))
			end

			newSpeed = flattenVectorAgainstWall(newSpeed, result.Normal)

		end
	end

	

	return newSpeed
end]]

return module
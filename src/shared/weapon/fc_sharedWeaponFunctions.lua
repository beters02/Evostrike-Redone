local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Strings = require(Framework.shfc_strings.Location)
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local MainObj = ReplicatedStorage:WaitForChild("main"):WaitForChild("obj")
local BulletModel = MainObj:WaitForChild("Bullet")
local BulletHole = MainObj:WaitForChild("BulletHole")
local WeaponFolder = ReplicatedStorage:WaitForChild("weapon")
local GlobalSounds = WeaponFolder:WaitForChild("obj"):WaitForChild("global"):WaitForChild("sounds") -- global weapon sounds (player hit, player killed, etc)
local WeaponRemotes = WeaponFolder:WaitForChild("remote")
local Particles = MainObj:WaitForChild("particles")
local EmitParticle = require(Framework.shfc_emitparticle.Location)
local Math = require(Framework.shfc_math.Location)
local States = require(Framework.shm_states.Location)

local module = {}

-- Weapon Spray Pattern Utility

--[[
	Spray Pattern Spring Parsing
]]

function module.checkSplitForNeg(split)
	for i, v in pairs(split) do
		if string.match(v, "neg") then
			split[i] = "-" .. v:sub(4, v:len())
		end
	end
	return split
end

function module.initStrings(str)--: tuple -- strings to be formatted on require
	--[[
		Range String format:
		"range_EndBulletNumber_StartValue-EndValue"
		
		Smooth Linear Progression from StartValue to EndValue
		Returns a tuple with -> EndBullet, StartValue, EndValue
	]]
	if string.match(str, "range") then
		local split = string.split(str, "_")
		local rangeSplit = string.split(split[3], "-")
		rangeSplit = module.checkSplitForNeg(rangeSplit)
		return tonumber(split[2]), tonumber(rangeSplit[1]), tonumber(rangeSplit[2])
	end

	--[[
		Constant String format:
		"const_EndBulletNumber_Value"
		
		Constant Value starting from current index and going to EndBulletNumber.
		Returns a tuple
	]]
	if string.match(str, "const") then--: EndBullet, Value
		local split = module.checkSplitForNeg(string.split(str, "_"))
		return tonumber(split[2]), tonumber(split[3])
	end
	
	--[[
		Speed String format:
		"speed_StartValue_EndValue_Speed"
		
		Lerp to end value using a set speed
		
		@return: tuple -> startValue, endValue, speed
	]]
	if string.match(str, 'speed') then
		local split = string.split(str, "_")
		return tonumber(split[2], split[3])
	end
end

function module.duringStrings(str): number -- strings to be formatted real time
	if string.match(str, "absr") then -- Absolute Value Random (1, -1)
		local chars = Strings.seperateToChar(string.gsub(str, "absr", ""))

		local numstr = ""
		for i, v in chars do
			if tonumber(v) or tostring(v) == "." then
				numstr = numstr .. v
			end
		end

		return (math.random(0, 1) == 1 and 1 or -1) * tonumber(numstr)
	end
end

-- Weapon Bullets

function module.CreateBulletHole(result)
	if not result then return end
	local normal = result.Normal
	local cFrame = CFrame.new(result.Position, result.Position + normal)
	local bullet_hole = BulletHole:Clone()
	bullet_hole.CFrame = cFrame
	bullet_hole.Anchored = false
	bullet_hole.CanCollide = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bullet_hole
	weld.Part1 = result.Instance
	weld.Parent = bullet_hole
	bullet_hole.Parent = workspace.Temp
	
	task.spawn(function()
		EmitParticle.EmitParticles(result.Instance, EmitParticle.GetBulletParticlesFromInstance(result.Instance), bullet_hole)
	end)
	
	Debris:AddItem(bullet_hole, 8)
	return bullet_hole
end

function module.CreateBullet(fromChar, endPos, client)
	local tool = fromChar:FindFirstChildWhichIsA("Tool")
	local startPos = tool.ServerModel.GunComponents.WeaponHandle.FirePoint.WorldPosition
	if client then
		startPos = workspace.CurrentCamera.viewModel.Equipped.ClientModel.GunComponents.WeaponHandle.FirePoint.WorldPosition
	end
	local part = BulletModel:Clone() --create bullet part
	part.Parent = workspace.Temp
	part.Size = Vector3.new(0.1, 0.1, 0.4)
	part.Position = startPos
	part.Transparency = 1
	part.CFrame = CFrame.lookAt(startPos, endPos)
	local tude = (startPos - endPos).magnitude --bullet speed
	local tv = tude/1100
	local ti = TweenInfo.new(tv) --bullet travel animation tween
	local goal = {Position = endPos}
	--bullet size animation tween
	local sizeti = TweenInfo.new(.2) --time it takes for bullet to grow
	local sizegoal = {Size = Vector3.new(0.1, 0.1, 0.7), Transparency =  0}
	local tween = Tween:Create(part, ti, goal)
	local sizetween = Tween:Create(part, sizeti, sizegoal)
	local finished = Instance.new("BindableEvent")
	
	task.delay(0.015, function() -- wait debug so the bullet is shown starting at the tip of the weapon
		tween:Play() -- play tweens and destroy bullet
		sizetween:Play()
		tween.Completed:Wait()
		part:Destroy()
		finished:Fire()
		Debris:AddItem(finished, 3)
	end)
	return part, finished
end

--[[
	FireBullet

	Replicates CreateBullet to all Clients except caster
]]

function module.FireBullet(fromChar, result, isHumanoid)
	if game:GetService("RunService"):IsServer() then return end
	local endPos = result.Position
	local bullet, bulletFinishedEvent = module.CreateBullet(fromChar, endPos, true)
	task.spawn(function()
		WeaponRemotes.replicate:FireServer("CreateBullet", fromChar, endPos, false)
	end)
	if not isHumanoid then
		task.spawn(function()
			module.CreateBulletHole(result)
			WeaponRemotes.replicate:FireServer("CreateBulletHole", {Position = result.Position, Instance = result.Instance, Normal = result.Normal})
		end)
	end
	bulletFinishedEvent.Event:Once(function()
		bulletFinishedEvent:Destroy()
	end)
end

-- Weapon Shot & Damage Registration

-- Utility

function util_getDamageFromHumResult(player, char, weaponOptions, pos, instance, normal, origin) -- player = damager
		
		-- register variables
        local hum = char.Humanoid
		if hum.Health <= 0 then return false end
        local distance = (pos - origin).Magnitude
        damage = weaponOptions.damage.base
		local instance = instance
		local calculateFalloff = true
		local min = weaponOptions.damage.damageFalloffMinimumDamage
		local particleFolderName = "Hit"
		local soundFolderName = "Bodyshot"
		local killed = false

		-- get hit bodypart
		if string.match(instance.Name, "Head") then

			-- apply head mult to base damage
			damage *= weaponOptions.damage.headMultiplier
			-- apply head mult to min damage
			min *= weaponOptions.damage.headMultiplier

			-- apply head falloff multiplier if necessary
			calculateFalloff = weaponOptions.damage.enableHeadFalloff and (weaponOptions.damage.headFalloffMultiplier or true) or false
			
			particleFolderName = "Headshot"
			soundFolderName = "Headshot"
		elseif string.match(instance.Name, "Leg") or string.match(instance.Name, "Foot") then
			damage *= weaponOptions.damage.legMultiplier
		end

		-- round damage to remove decimals
		damage = math.round(damage)

		-- calculate damage falloff
		if distance > weaponOptions.damage.damageFalloffDistance and calculateFalloff then
			local diff = distance - weaponOptions.damage.damageFalloffDistance
			damage = math.max(damage - diff * (weaponOptions.damage.damageFalloffPerMeter * (type(calculateFalloff) == "number" and calculateFalloff or 1)), min)
		end

		-- see if player will be killed after damage is applied
		killed = hum.Health <= damage and true or false

        if RunService:IsServer() then

			-- set ragdoll variations
			char:SetAttribute("bulletRagdollNormal", -normal)
			char:SetAttribute("bulletRagdollKillDir", (player.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Unit)
			char:SetAttribute("lastHitPart", instance.Name)
			
			-- apply damage
            hum:TakeDamage(damage)

			-- apply tag so we can easily access damage information
            module.TagPlayer(char, player)

		end
	return damage, particleFolderName, killed, char, soundFolderName
end

-- Functions

--[[
	RegisterShot

	Fires Bullet, Creates BulletHole and Registers Damage
	Also compensates for lag if needed
]]

function module.RegisterShot(player, weaponOptions, result, origin, dir, registerTime)
	if not result.Instance then return false end

	local particleFolderName
	local soundFolderName
	local hole = false
	local isHumanoid = false
	local damage = false
	local killed = false
	local _

	-- if we are shooting a humanoid character
	local char = result.Instance:FindFirstAncestorWhichIsA("Model")
	if char and char:FindFirstChild("Humanoid") then
		isHumanoid = true
	end

	if RunService:IsClient() then
		task.spawn(function()
			if not isHumanoid then return end

			-- get damage, folders, killedBool
			damage, particleFolderName, killed, _, soundFolderName = util_getDamageFromHumResult(player, char, weaponOptions, result.Position, result.Instance, result.Normal, origin)
			local instance = result.Instance

			-- particles
			task.spawn(function()
				if killed then
					EmitParticle.EmitParticles(instance, Particles.Blood.Kill:GetChildren(), instance, char)
				end
				if not particleFolderName then return end
				EmitParticle.EmitParticles(instance, Particles.Blood[particleFolderName]:GetChildren(), instance)
			end)
			
			-- sounds
			if soundFolderName then
				task.spawn(function()
					module.PlayGlobalSound(player.Character, "PlayerHit", soundFolderName)
				end)
			end

		end)
		return module.FireBullet(player.Character, result, isHumanoid)
	elseif isHumanoid then
		return util_getDamageFromHumResult(player, char, weaponOptions, result.Position, result.Instance, result.Normal, origin)
	end

	return false
end

function module.TagPlayer(tagged: Model, tagger: Player)
	local gotPlayer = Players:GetPlayerFromCharacter(tagged)
	if not gotPlayer then return end

	local gotTag = tagged:FindFirstChild("DamageTag")
	if gotTag then gotTag:Destroy() end

	gotTag = Instance.new("ObjectValue")
	gotTag.Name = "DamageTag"
	gotTag.Value = tagger
	gotTag.Parent = tagged
	return gotTag
end

-- Weapon Sounds

function module.PlaySound(playFrom, weaponName, sound) -- if not weaponName, sound will not be destroyed upon recreation
	local c: Sound

	-- destroy sound on recreation if weaponName is specified
	if weaponName then
		c = playFrom:FindFirstChild(weaponName .. "_" .. sound.Name) :: Sound
		if c then
			c:Stop()
			c:Destroy()
		end
	else
		weaponName = "Weapon"
	end

	c = sound:Clone() :: Sound
	c.Name = weaponName .. "_" .. sound.Name
	c.Parent = playFrom
	c:Play()
	Debris:AddItem(c, c.TimeLength + 0.06)
	return c
end

-- global sounds typically consist of multiple sounds,
-- therefore the PlayGlobalSound will play all sounds
-- that are children to the specified SoundFolder
function module.PlayGlobalSound(playFrom, ...)
	local soundFolder

	local globalSoundFolderName, a, b = ...
	if globalSoundFolderName == "PlayerHit" then
		local playerHitFolderName, soundName = a, b
		soundFolder = GlobalSounds.PlayerHit[playerHitFolderName]
	end

	for _, sound in pairs(soundFolder:GetChildren()) do
		if not sound:IsA("Sound") then continue end
		module.PlaySound(playFrom, false, sound)
	end
end

-- Accuracy Utility

-- Add Absr Random 1-add value to Vector2
function util_vec2AddWithAbsrR1(vec, add)
	if add == 0 then return vec end
	return Vector2.new(vec.X + Math.absValueRandom(math.random(1, add), vec.Y + Math.absValueRandom(math.random(1, add))))
end

-- Add Fixed Absr Random add-add value to Vector2
function util_vec2AddWithFixedAbsrRR(vec, addX, addY)
	addX = Math.frand(addX)
	addY = Math.frand(addY)
	return Vector2.new(vec.X + addX, vec.Y + addY)
end

-- Accuracy

function module.GetMovementInaccuracyVector2(player, baseAccuracy, weaponOptions)
	local movementConfig = require(player.Character.movementScript.Configuration)

	local _x
	local _y
	if type(baseAccuracy) == "table" then
		_x, _y = baseAccuracy[2], baseAccuracy[3] -- recoilVectorX, recoilVectorY
		baseAccuracy = baseAccuracy[1]
	end
	
	-- movement speed inacc
	local movementSpeed = player.Character.HumanoidRootPart.Velocity.Magnitude
	if States.GetStateVariable("Movement", "crouching") then
		baseAccuracy *= 1.5
	elseif (movementSpeed > 6 or States.GetStateVariable("Movement", "landing")) and movementSpeed < movementConfig.walkMoveSpeed then
		baseAccuracy = weaponOptions.accuracy.walk
	elseif movementSpeed >= movementConfig.walkMoveSpeed + math.round((movementConfig.groundMaxSpeed - movementConfig.walkMoveSpeed)/2) then
		baseAccuracy = weaponOptions.accuracy.run
	end
	
	-- jump inacc
	if not require(Framework.shfc_sharedMovementFunctions.Location).IsGrounded(player) then
		baseAccuracy += weaponOptions.accuracy.jump
	end

	movementConfig = nil
	
	return util_vec2AddWithFixedAbsrRR(Vector2.zero, _x and _x * baseAccuracy or baseAccuracy, _y and _y * baseAccuracy or baseAccuracy)
end

function module.CalculateAccuracy(player, recoilVector3, weaponOptions, storedVar) -- cvec2 is client accuracy re-registration
	local acc

	-- get base accuracy & apply movement inaccuracy

	-- spread weapons rely on weapon accuracy for it's functionality,
	-- so we will apply that here if necessary.

	local baseAccuracy = storedVar.currentBullet == 1 and weaponOptions.accuracy.firstBullet or weaponOptions.accuracy.base
	if storedVar.currentBullet ~= 1 and weaponOptions.accuracy.spread then
		baseAccuracy = {baseAccuracy, recoilVector3.X, recoilVector3.X}
	end

	acc = module.GetMovementInaccuracyVector2(
		player,
		baseAccuracy,
		weaponOptions
	)

	-- randomize acc abs
	acc = Vector2.new(Math.absr(acc.X), Math.absr(acc.Y))

	return acc
end

function module.CalculateVectorRecoil(recoilVector3, weaponOptions, storedVar)

	-- before we were applying a mmabs of 1.5 on the y(side), and a math.min of 1 on the x(up)
	-- this was a weird way to do it
	--local new = Vector2.new(Math.mmabs(recoilVector3.Y, 1.5), math.min(recoilVector3.X, 1))

	-- we have to convert the table back from Up, Side to Side, Up
	-- this is because the Vector3 is made to be used with CFrames,
	-- the accuracy vector2's are used on direction Vector3s.
	local new = Vector2.new(recoilVector3.Y, recoilVector3.X)

	-- first bullet remove vector recoil
	if storedVar.currentBullet == 1 then
		new = Vector2.zero
		storedVar.lastYVec = 0
	else
		-- if the add vector is 0, don't keep climbing the vec recoil
		if new.Y ~= 0 then
			storedVar.lastYVec = new.Y
		end
	end

	-- apply spread and return if spread only
	if weaponOptions.spread then
		return Vector2.new(Math.absr(new.X, new.Y))
	end

	local offset = weaponOptions.fireVectorCameraOffset * (storedVar.currentVectorModifier or 1)
	return Vector2.new(new.X, storedVar.lastYVec) * offset, storedVar
end

function module.GetAccuracyAndRecoilDirection(player, mray, currVecRecoil, weaponOptions, storedVar)
	local acc

	-- calculate accuracy
	acc = module.CalculateAccuracy(player, currVecRecoil, weaponOptions, storedVar)
	acc /= 550 -- Arbitrary accuracy modifier

	-- resolve accuracy being too strong on Up and not strong enough on Side
	--acc = Vector2.new(acc.X*1.2, acc.Y*0.8)

	-- calculate vector recoil
	local vecr
	vecr, storedVar = module.CalculateVectorRecoil(currVecRecoil, weaponOptions, storedVar)
	vecr /= 500

	-- combine acc and vec recoil
	acc += vecr

	-- register client ray using
	-- client accuracy and vector recoil for direction
	--local direction = mray.Direction
	--[[local direction = storedVar.originPoint and storedVar.originPoint.Direction
	if direction then
		--print(direction)
		-- apply y offset according to new mouse pos
		direction = Vector3.new(
			mray.Direction.X,
			direction.Y > 0 and direction.Y + (mray.Direction.Y + direction.Y)/1.8 or direction.Y + (mray.Direction.Y - direction.Y)/1.8,
			mray.Direction.Z
		)
	else
		direction = mray.Direction
	end]]

	local direction = mray.Direction
	

	return Vector3.new(direction.X + (acc.X)*(direction.X > 0 and 1 or -1), direction.Y + acc.Y, direction.Z + (acc.X)*(direction.Z > 0 and 1 or -1)).Unit
end

-- Fire Ray

function module.getFireCastParams(player, camera)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, camera, workspace.Temp}
	params.CollisionGroup = "Bullets"
	return params
end

function module.createRayInformation(unitRay, result)
	if not result then return end
	return {origin = unitRay.Origin, direction = unitRay.Direction, instance = result.Instance, position = result.Position, normal = result.Normal, distance = result.Distance, material = result.Material}
end

return module
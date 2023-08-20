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
local WeaponRemotes = WeaponFolder:WaitForChild("remote")
local EmitParticle = require(Framework.shfc_emitparticle.Location)

local module = {}

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

function module.numberAbsoluteValueCheck(str)
	
end

-- RETURN NUMBERS FROM STRINGS
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
		--WeaponRemotes.Replicate:FireServer("CreateBullet", fromChar, endPos)
	end)
	if not isHumanoid then
		task.spawn(function()
			module.CreateBulletHole(result)
		end)
	end
	bulletFinishedEvent.Event:Once(function()
		bulletFinishedEvent:Destroy()
	end)
end

-- player = damager
local function getDamageFromHumResult(player, char, weaponOptions, pos, instance, normal, origin)
		
		-- register variables
        local hum = char.Humanoid
		if hum.Health <= 0 then return false end
        local distance = math.abs((pos - origin).Magnitude)
        damage = weaponOptions.damage.base
		local instance = instance
		local calculateFalloff = true
		local particleFolderName = "Hit"
		local soundFolderName = "Bodyshot"
		local killed = false

		-- get hit bodypart
		if string.match(instance.Name, "Head") then
			damage *= weaponOptions.damage.headMultiplier
			calculateFalloff = weaponOptions.damage.enableHeadFalloff or false
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
			damage = math.max(damage - diff * weaponOptions.damage.damageFalloffPerMeter, weaponOptions.damage.damageFalloffMinimumDamage)
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

--[[
	RegisterShot

	Fires Bullet, Creates BulletHole and Registers Damage
	Also compensates for lag if needed
]]

local Particles = MainObj:WaitForChild("particles")

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
			damage, particleFolderName, killed, _, soundFolderName = getDamageFromHumResult(player, char, weaponOptions, result.Position, result.Instance, result.Normal, origin)
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
		return getDamageFromHumResult(player, char, weaponOptions, result.Position, result.Instance, result.Normal, origin)
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

--[[
	Sound
]]

-- if not weaponName, sound will not be destroyed upon recreation
function module.PlaySound(playFrom, weaponName, sound)
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

-- global weapon sounds (player hit, player killed, etc)
local GlobalSounds = WeaponFolder:WaitForChild("obj"):WaitForChild("global"):WaitForChild("sounds")

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

local quickabsr = function(a) return a * (math.random(1, 2) == 1 and -1 or 1) end
local function quickMaxOrMin(v, m) return v > 0 and math.min(v, m) or math.max(v, -m) end

local function quickVecAdd(vec, add)
	if add == 0 then return vec end
	local a1 = math.random(1, add)
	return Vector2.new(vec.X + quickabsr(a1), vec.Y + quickabsr(math.random(1, add)))
end

local function quickVecAddRandomAbsRandomXY(vec, addX, addY)
	addX = addX > 0 and math.random(-addX, addX) or math.random(addX, -addX)
	addY = addY > 0 and math.random(-addY, addY) or math.random(addY, -addY)
	return Vector2.new(vec.X + addX, vec.Y + addY)
end

local function randomize(num)
	return math.round(math.random(100, 200)) == 1 and num or -num
end

function module.getMovementInaccuracyVector2(firstBullet, player, speed, weaponOptions)
	local toAdd = 0
	local move = false
	local first = false
	if not weaponOptions.accuracy.firstBullet or not firstBullet then
		toAdd = weaponOptions.accuracy.base
	else first = true end
	
	-- movement speed inacc
	local movementSpeed = speed or player.Character.HumanoidRootPart.Velocity.magnitude
	if movementSpeed > 8 and movementSpeed < 12 then
		toAdd = weaponOptions.accuracy.walk
		move = true
	elseif movementSpeed >= 12 then
		toAdd = weaponOptions.accuracy.run
		move = true
	end
	
	-- jump inacc
	if require(Framework.shfc_sharedMovementFunctions.Location).IsPlayerGrounded(player) then
		toAdd += weaponOptions.accuracy.jump
		move = true
	end
	
	local acc = quickVecAdd(Vector2.zero, toAdd)
	if not move and not first then acc = Vector2.new(acc.X, quickMaxOrMin(acc.Y, 1.5)) end
	return acc
end

function module.CalculateAccuracy(player, weaponOptions, currentBullet, recoilVector3, storedVar, currentMovementSpeed, cvec2) -- cvec2 is client accuracy re-registration
	-- var
	local acc
	local vecmod = storedVar.currentVectorModifier or 1
	local offset = weaponOptions.fireVectorCameraOffset * vecmod

	local newy
	if recoilVector3.Y < 0 then
		newy = math.max(recoilVector3.Y, -1.5)
	else
		newy = math.min(recoilVector3.Y, 1.5)
	end
	local new = Vector2.new(newy, math.min(recoilVector3.X, 1))

	-- grow vector offset for first 4 bullets
	-- bullets would shoot up after the first bullet without this
	--[[if currentBullet < 9 then
		offset *= currentBullet/9
	end]]

	-- first bullet acc
	if currentBullet == 1 then
		if weaponOptions.accuracy.firstBullet then
			new = Vector2.zero
		end
		acc = cvec2 or module.getMovementInaccuracyVector2(true, player, currentMovementSpeed, weaponOptions)
		storedVar.lastYAcc = acc.Y
	else
		acc = cvec2 or module.getMovementInaccuracyVector2(false, player, currentMovementSpeed, weaponOptions)

		-- if the add vector is 0, don't keep climbing the vec recoil
		if new.Y ~= 0 then
			storedVar.lastYAcc = new.Y
		end
	end

	-- apply spread and return if spread only
	if weaponOptions.spread then
		acc = Vector2.new(randomize(acc.X + recoilVector3.Y), randomize(acc.Y + recoilVector3.X))
		return quickVecAddRandomAbsRandomXY(acc, new.X * offset.X, new.Y * offset.Y), storedVar
	end

	-- randomize acc abs
	acc = Vector2.new(randomize(acc.X), randomize(acc.Y))

	-- apply offset and acc
	new = Vector2.new(acc.X + (new.X * offset.X), acc.Y + (storedVar.lastYAcc * offset.Y))
	return new, storedVar
end

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
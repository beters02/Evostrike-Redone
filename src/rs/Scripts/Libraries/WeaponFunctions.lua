local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local BulletModel = ReplicatedStorage:WaitForChild("Objects"):WaitForChild("Bullet")
local WeaponRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Weapon")
local EmitParticle = require(ReplicatedStorage.Scripts.Functions.EmitParticle)

local module = {}

function module.CreateBulletHole(result)
	if not result then return end
	local normal = result.Normal
	local cFrame = CFrame.new(result.Position, result.Position + normal)
	local bullet_hole = game:GetService("ReplicatedStorage").Objects.BulletHole:Clone()
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
	WeaponRemotes.Replicate:FireServer("CreateBullet", fromChar, endPos)
	if not isHumanoid then
		module.CreateBulletHole(result)
	end
	bulletFinishedEvent.Event:Once(function()
		bulletFinishedEvent:Destroy()
	end)
end

local function getDamageFromHumResult(player, char, weaponOptions, pos, instance, normal, origin)
		
		-- register variables
        local hum = char.Humanoid
		if hum.Health <= 0 then return false end
        local distance = math.abs((pos - origin).Magnitude)
        damage = weaponOptions.damage.base
		local instance = instance
		local calculateFalloff = true
		local particleFolderName = "Hit"
		local killed = false

		-- get hit bodypart
		if string.match(instance.Name, "Head") then
			damage *= weaponOptions.damage.headMultiplier
			calculateFalloff = weaponOptions.damage.enableHeadFalloff or false
			particleFolderName = "Headshot"
		elseif string.match(instance.Name, "Leg") or string.match(instance.Name, "Foot") then
			damage *= weaponOptions.damage.legMultiplier
		end

		-- round damage to remove decimals
		damage = math.round(damage)

		-- calculate damage falloff
		if distance > weaponOptions.damage.damageFalloffDistance and calculateFalloff then
			local diff = distance - weaponOptions.damage.damageFalloffDistance
			--print(damage - diff * weaponOptions.damage.damageFalloffPerMeter)
			damage = math.max(damage - diff * weaponOptions.damage.damageFalloffPerMeter, weaponOptions.damage.damageFalloffMinimumDamage)
			--print(damage)
		end

		-- see if player will be killed after damage is applied
		killed = hum.Health <= damage and true or false

        if RunService:IsServer() then

			-- set ragdoll variations
			char:SetAttribute("bulletRagdollNormal", -normal)
			char:SetAttribute("lastHitPart", instance.Name)
			char:SetAttribute("impulseModifier", 1)
			
			-- apply damage
            hum:TakeDamage(damage)

			-- apply tag so we can easily access damage information
            module.TagPlayer(char, player)

		end
	return damage, particleFolderName, killed, char
end

--[[
	RegisterShot

	Fires Bullet, Creates BulletHole and Registers Damage
	Also compensates for lag if needed
]]

function module.RegisterShot(player, weaponOptions, result, origin, dir, registerTime)
	if not result.Instance then return false end

	local hole = false
	local isHumanoid = false
	local damage = false
	local particleFolderName
	local killed = false

	-- if we are shooting a humanoid character
	local char = result.Instance:FindFirstAncestorWhichIsA("Model")
	if char and char:FindFirstChild("Humanoid") then
		isHumanoid = true
	end

	if RunService:IsClient() then
		task.spawn(function()
			if not isHumanoid then return end
			-- emit particles next frame
			damage, particleFolderName, killed = getDamageFromHumResult(player, char, weaponOptions, result.Position, result.Instance, result.Normal, origin)
			local instance = result.Instance
			if killed then
				EmitParticle.EmitParticles(instance, ReplicatedStorage.Objects.Particles.Blood.Kill:GetChildren(), instance, char)
			end
			EmitParticle.EmitParticles(instance, ReplicatedStorage.Objects.Particles.Blood[particleFolderName]:GetChildren(), instance)
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

return module
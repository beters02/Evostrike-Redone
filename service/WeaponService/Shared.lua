type Character = Model
export type ShotResultData = {
	shooter: Player,
	tool: Tool,
	model: Model,
	weaponOptions: {},
	result: RaycastResult?,
	origin: Vector3,
	hitCharacter: Character?,
	isBangable: boolean,
	wallbangDmgMult: number
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local WeaponServiceAssets = ReplicatedStorage.Services.WeaponService.ServiceAssets
local BulletModel = WeaponServiceAssets.Models:WaitForChild("Bullet")
local BulletHole = WeaponServiceAssets.Models:WaitForChild("BulletHole")
local EmitParticle = require(ReplicatedStorage.lib.fc_emitparticle)
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local EvoPlayer = require(Framework.Module.EvoPlayer)
local GlobalSounds = Framework.Service.WeaponService.ServiceAssets.Sounds
local Particles = ReplicatedStorage.Services.WeaponService.ServiceAssets.Emitters
local Replicate = Framework.Service.WeaponService.Events.Replicate
local PlayerAttributes = require(Framework.Module.PlayerAttributes)

local Shared = {}
Shared.WallbangMaterials = {
	LightMetal = 0.7,
	HeavyMetal = 0.4,
	LightWood = 0.85,
	HeavyWood = 0.5,
	Ignore = 1,
}

function Shared.CreateBulletHole(result)
	if not result then return end

	local normal = result.Normal
	local cFrame = CFrame.new(result.Position, result.Position + normal)
	local bullet_hole = BulletHole:Clone()
	bullet_hole.CFrame = cFrame
	bullet_hole.Anchored = true
	bullet_hole.CanCollide = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bullet_hole
	weld.Part1 = result.Instance
	weld.Parent = bullet_hole
	bullet_hole.Parent = workspace.Temp

	local isBangable = false
	local _succ = pcall(function()
		isBangable = result.IsBangableWall
	end)
	isBangable = _succ and isBangable or false
	
    EmitParticle.EmitParticles(result.Instance, EmitParticle.GetBulletParticlesFromInstance(result.Instance), bullet_hole, nil, nil, nil, isBangable)
	
	Debris:AddItem(bullet_hole, 8)
	return bullet_hole
end

function Shared.CreateBullet(tool, endPos, fromModel)

	--create bullet part
	local part = BulletModel:Clone()

	local pos
	if fromModel then
		pos = fromModel.GunComponents.WeaponHandle.FirePoint.WorldPosition
	else
		pos = tool.ServerModel.GunComponents.WeaponHandle.FirePoint.WorldPosition
	end

	part.Size = Vector3.new(0.1, 0.1, 0.4)
	part.Position = pos
	part.CFrame = CFrame.new(pos)
	part.Transparency = 1
	part.CFrame = CFrame.lookAt(pos, endPos)
	part.CollisionGroup = "None"
	part.Parent = workspace.Temp

	local tween = TweenService:Create(
		part,
		TweenInfo.new(((pos - endPos).magnitude) * (1 / 900)), -- 900 studs a sec
		{Position = endPos}
	)

	-- create finished event to fire
	local finished = Instance.new("BindableEvent")

	task.wait()

	tween:Play() -- play tweens and destroy bullet
	tween.Completed:Wait()

	-- we anchor and then let the trails finish
	part.Anchored = true
	part.Transparency = 1
	Debris:AddItem(part, 3)

	-- fire finished event
	finished:Fire()
	Debris:AddItem(finished, 3)

	return part, finished
end

function Shared.RegisterShot(resultData: ShotResultData)
	if not resultData.result or not resultData.result.Instance then return false end
	local killed = false

	if not resultData.model then
		resultData.model = resultData.tool:WaitForChild("ServerModel")
	end

	-- if we are shooting a humanoid character
	local isHumanoid = true
	local char = resultData.hitCharacter
	if not char then
		char = resultData.result.Instance:FindFirstAncestorWhichIsA("Model")
		if not char or not char:FindFirstChild("Humanoid") then
			isHumanoid = false
		end
	end

	if RunService:IsClient() then
		if isHumanoid then
			_, _, killed = getDamageFromHumanoidResult(resultData)
			Shared.PlayerHitParticles(char, resultData.result.Instance, killed)
			Shared.PlayerHitSounds(char, resultData.result.Instance, killed)
		end
		
		return Shared.FireReplicatedBulletFromClient(resultData, isHumanoid)
	end

	if not isHumanoid then
		return false
	end
	return getDamageFromHumanoidResult(resultData)
end

function Shared.FireReplicatedBulletFromClient(resultData: ShotResultData, isHumanoid: boolean)
	if game:GetService("RunService"):IsServer() then return end
	Shared.CreateBullet(resultData.tool, resultData.result.Position, resultData.model)
	Replicate:FireServer("CreateBullet", resultData.tool, resultData.result.Position)
	if not isHumanoid then
		local fakeResult = {
			Position = resultData.result.Position,
			Instance = resultData.result.Instance,
			Normal = resultData.result.Normal,
			IsBangableWall = resultData.isBangable
		}
		Shared.CreateBulletHole(fakeResult)
		Replicate:FireServer("CreateBulletHole", fakeResult)
	end
end

function Shared.TagPlayer(tagged: Model, tagger: Player)
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

function Shared.PlayerHitSounds(character, hitPartInstance, wasKilled) -- Player Hit Sounds is played Last, just after PlayerHitParticles.
    if character:GetAttribute("ClientKillSoundPlayed") then return end

    if not wasKilled then
        local lrh = character:GetAttribute("LastRegisteredHealth")
        wasKilled = (lrh and lrh <= 0)
    end

    -- get soundfolder from wasKilled or Head/Body
    local soundFolder

    if wasKilled then
        character:SetAttribute("ClientKillSoundPlayed", true)
        task.spawn(function()
            playAllSoundsIn(GlobalSounds.PlayerKilled, character)
        end)
    end

    local ignore = false

    if string.match(string.lower(hitPartInstance.Name), "head") then
        soundFolder = GlobalSounds.PlayerHit.Headshot
        if character:GetAttribute("HelmetBroken") then
            character:SetAttribute("HelmetBroken", false)
            ignore = {headshot1 = not wasKilled}
        else
            ignore = {helmet = true, helmet1 = true}
        end
    else
        soundFolder = GlobalSounds.PlayerHit.Bodyshot
    end

    task.spawn(function()
        playAllSoundsIn(soundFolder, character, ignore)
    end)
end

function Shared.PlayerHitParticles(character, hitPartInstance, wasKilled)

    if not wasKilled then
        local lrh = character:GetAttribute("LastRegisteredHealth")
        wasKilled = (lrh and lrh <= 0)
    end

    -- kill particles
    if wasKilled then
        task.spawn(function() EmitParticle.EmitParticles(hitPartInstance, Particles.Blood.Kill:GetChildren(), hitPartInstance, character) end)
    end

    -- hit body/head particles
    local particleFolder
    if string.match(string.lower(hitPartInstance.Name), "head") then
        if character:GetAttribute("HelmetBroken") then
            particleFolder = Particles.Blood.Headshot.Helmet
        else
            particleFolder = Particles.Blood.Headshot.NoHelmet
        end
    else
        particleFolder = Particles.Blood.Hit
    end

    task.spawn(function() EmitParticle.EmitParticles(hitPartInstance, particleFolder:GetChildren(), hitPartInstance) end)
end



function getDamageFromHumanoidResult(resultData: ShotResultData)
	
	local char = resultData.hitCharacter
	local weaponOptions = resultData.weaponOptions
	local instance = resultData.result.Instance

	-- register variables
	local hum = char.Humanoid
	if hum.Health <= 0 then return false end

	local distance = (resultData.result.Position - resultData.result.Origin).Magnitude
	local damage = weaponOptions.damage.base

	local calculateFalloff = 1
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
		calculateFalloff = weaponOptions.damage.enableHeadFalloff and (weaponOptions.damage.headFalloffMultiplier or 1) or false
		
		particleFolderName = "Headshot"
		soundFolderName = "Headshot"

	elseif string.match(instance.Name, "LowerLeg") or string.match(instance.Name, "Foot") then
		damage *= weaponOptions.damage.legMultiplier
	end

	-- calculate damage falloff
	if distance > weaponOptions.damage.damageFalloffDistance and calculateFalloff then
		local diff = distance - weaponOptions.damage.damageFalloffDistance
		damage = math.max(damage - diff * (weaponOptions.damage.damageFalloffPerMeter * calculateFalloff), min)
		damage = math.min(damage, weaponOptions.damage.base)
	end

	-- wallbang multiplier
	if resultData.wallbangDmgMult then damage *= resultData.wallbangDmgMult end

	-- round damage to remove decimals
	damage = math.round(damage)

	-- set ragdoll variations

	char:SetAttribute("bulletRagdollNormal", -resultData.result.Normal)
	char:SetAttribute("bulletRagdollKillDir", (resultData.shooter.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Unit)
	char:SetAttribute("lastHitPart", instance.Name)
	char:SetAttribute("lastUsedWeapon", weaponOptions.name)
	char:SetAttribute("lastUsedWeaponDestroysHelmet", weaponOptions.damage.destroysHelmet or false)
	char:SetAttribute("lastUsedWeaponHelmetMultiplier", weaponOptions.damage.helmetMultiplier or 1)

	-- apply damage
	damage, killed = EvoPlayer:TakeDamage(char, damage, resultData.shooter.Character, weaponOptions.name, instance.Name)

	if RunService:IsServer() then
		-- apply tag so we can easily access damage information
		Shared.TagPlayer(char, resultData.shooter)
	end

	return damage, particleFolderName, killed, char
end

function playSound(playFrom, weaponName, sound) -- if not weaponName, sound will not be destroyed upon recreation
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
	Debris:AddItem(c, c.TimeLength + 2)
	return c
end

function playAllSoundsIn(where: Folder, playFrom: any, ignoreNames: table)
    for _, sound in pairs(where:GetChildren()) do
		if not sound:IsA("Sound") or (ignoreNames and ignoreNames[sound.Name]) then continue end
        playSound(playFrom, false, sound)
	end
end

return Shared
-- [[ Purpose: organize sharedWeaponFunctions, bulletHit particles and sounds ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local EmitParticle = require(Framework.shfc_emitparticle.Location)
local GlobalSounds = ReplicatedStorage.Services.WeaponService.ServiceAssets.Sounds
local Particles = ReplicatedStorage.Services.WeaponService.ServiceAssets.Emitters

local util = {}

function _PlaySound(playFrom, weaponName, sound) -- if not weaponName, sound will not be destroyed upon recreation
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

function _PlayAllSoundsIn(where: Folder, playFrom: any, ignoreNames: table)
    for _, sound in pairs(where:GetChildren()) do
		if not sound:IsA("Sound") or (ignoreNames and ignoreNames[sound.Name]) then continue end
        _PlaySound(playFrom, false, sound)
	end
end

function util.PlayerHitSounds(character, hitPartInstance, wasKilled) -- Player Hit Sounds is played Last, just after PlayerHitParticles.
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
            _PlayAllSoundsIn(GlobalSounds.PlayerKilled, character)
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

    local testParent = RunService:IsClient() and game.Players.LocalPlayer.Character or character
    task.spawn(function()
        --_PlayAllSoundsIn(soundFolder, character, ignore)
        _PlayAllSoundsIn(soundFolder, testParent, ignore)
    end)
end

function util.PlayerHitParticles(character, hitPartInstance, wasKilled)

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

return util
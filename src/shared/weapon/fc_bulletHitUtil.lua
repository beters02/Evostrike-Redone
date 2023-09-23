-- [[ Purpose: organize sharedWeaponFunctions, bulletHit particles and sounds ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GlobalSounds = ReplicatedStorage.Services.WeaponService.ServiceAssets.Sounds
local Debris = game:GetService("Debris")
local EmitParticle = require(Framework.shfc_emitparticle.Location)
local MainObj = ReplicatedStorage:WaitForChild("main"):WaitForChild("obj")
local Particles = MainObj:WaitForChild("particles")

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

function util.PlayerHitSounds(character, hitPartInstance, wasKilled)
    if character:GetAttribute("ClientKillSoundPlayed") then return end

    -- get soundfolder from wasKilled or Head/Body
    local soundFolder
    local ignore
    if wasKilled then
        character:SetAttribute("ClientKillSoundPlayed", true)
        task.spawn(function()
            _PlayAllSoundsIn(GlobalSounds.PlayerKilled, character)
        end)
    end

    if string.match(string.lower(hitPartInstance.Name), "head") then
        soundFolder = GlobalSounds.PlayerHit.Headshot
        if not character:GetAttribute("Helmet") then -- ignore helmet sound for no helmet
            ignore = {helmet = "helmet"}
        end
    else
        soundFolder = GlobalSounds.PlayerHit.Bodyshot
    end

    task.spawn(function()
        _PlayAllSoundsIn(soundFolder, character, ignore)
    end)
end

function util.PlayerHitParticles(character, hitPartInstance, wasKilled)
    -- kill particles
    if wasKilled then
        task.spawn(function() EmitParticle.EmitParticles(hitPartInstance, Particles.Blood.Kill:GetChildren(), hitPartInstance, character) end)
    end

    -- hit body/head particles
    local particleFolder
    if string.match(string.lower(hitPartInstance.Name), "head") then
        particleFolder = Particles.Blood.Headshot
    else
        particleFolder = Particles.Blood.Hit
    end
    task.spawn(function() EmitParticle.EmitParticles(hitPartInstance, particleFolder:GetChildren(), hitPartInstance) end)
end

return util
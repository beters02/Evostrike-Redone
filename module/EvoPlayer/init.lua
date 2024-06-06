--[[ Purpose: Centralizing Evostrike Player Functionality ]]

local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Events = script:WaitForChild("Events")
local DiedEvent = Events.PlayerDiedRemote
local PlayerData = require(ReplicatedStorage.Modules.PlayerData)
local BotServiceModule = ReplicatedStorage.Services.BotService
local GlobalSounds = ReplicatedStorage.Services.WeaponService.ServiceAssets.Sounds
local StoredDamageInformation = require(script:WaitForChild("StoredDamageInformation"))
local PlayerAttributes = require(ReplicatedStorage.Modules.PlayerAttributes)

local EvoPlayer = {

    -- These are functions that execute when the player is loaded.
    LoadingFunctions = { } -- Server: playerName = {callback}  Client: {callback}
}

function setCharAttribute(player, attribute, value)
    if RunService:IsServer() then
        PlayerAttributes:SetCharacterAttribute(player, attribute, value)
    else
        PlayerAttributes:SetCharacterAttributeAsync(player, attribute, value)
    end
end

function getCharAttribute(player, attribute)
    return PlayerAttributes:GetCharacterAttribute(player, attribute)
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

function playerHitSoundsClient(damagedChar, damagerChar, wasKilled, hitPart)
    local plr = Players:GetPlayerFromCharacter(damagedChar) or {Name = "BOT_" .. damagedChar.Name}
    local ignore = false
    local killSoundPlayed = getCharAttribute(plr, "ClientKillSoundPlayed")
    local helmet = getCharAttribute(plr, "Helmet")
    local helmetBroken = getCharAttribute(plr, "HelmetBroken")

    local soundFolder

    if wasKilled then
        --damagedChar:SetAttribute("ClientKillSoundPlayed", true)
        setCharAttribute(plr, "ClientKillSoundPlayed", true)
        task.spawn(function()
            playAllSoundsIn(GlobalSounds.PlayerKilled, damagedChar)
        end)
    end

    if string.match(string.lower(hitPart), "head") and not killSoundPlayed then
        soundFolder = GlobalSounds.PlayerHit.Headshot

        if helmet or helmetBroken then
            setCharAttribute(plr, "HelmetBroken", false)
            ignore = {headshot1 = not wasKilled}
        else
            ignore = {helmet = true, helmet1 = true}
        end

    else
        soundFolder = GlobalSounds.PlayerHit.Bodyshot
    end

    local testParent = RunService:IsClient() and game.Players.LocalPlayer.Character or damagedChar
    task.spawn(function()
        --_PlayAllSoundsIn(soundFolder, character, ignore)
        playAllSoundsIn(soundFolder, testParent, ignore)
    end)
end

--@summary Correctly apply damage to the player, checking for shields
--         Plays necessary Sounds
function EvoPlayer:TakeDamage(character, damage, damager, weaponUsed, hitPart)
    if damager and damager.Humanoid.Health <= 0 then return 0 end
    if not EvoPlayer:CanDamage(character) then return 0 end

    --[[local shield = character:GetAttribute("Shield") or 0
    local helmet = character:GetAttribute("Helmet") or false
    local hitPart = character:GetAttribute("lastHitPart") or "Head"
    local destroysHelmet = character:GetAttribute("lastUsedWeaponDestroysHelmet") or false
    local helmetMultiplier = character:GetAttribute("lastUsedWeaponHelmetMultiplier") or 1]]
    local damagedPlayer = Players:GetPlayerFromCharacter(character) or false
    local damagerPlayer = Players:GetPlayerFromCharacter(damager)
    local attributePlayer = damagedPlayer or {Name = "BOT_" .. character.Name}
    local isBot = not damagedPlayer

    local shield = getCharAttribute(attributePlayer, "Shield") or 0
    local helmet = getCharAttribute(attributePlayer, "Helmet") or false
    --local hitPart = getCharAttribute(damagedPlayer, "lastHitPart") or "Head"
    local destroysHelmet = getCharAttribute(attributePlayer, "lastUsedWeaponDestroysHelmet") or false
    local helmetMultiplier = getCharAttribute(attributePlayer, "lastUsedWeaponHelmetMultiplier") or 1
    hitPart = hitPart or "Head"

    local absoluteDamage = damage

    local damageAppliedToCharacter = true
    local killed = false
    local isHeadShot = false

    if string.find(string.lower(hitPart), "head") then
        isHeadShot = true

        if helmet then
            if destroysHelmet then
                setCharAttribute(attributePlayer, "Helmet", false)
                setCharAttribute(attributePlayer, "HelmetBroken", true)
                setCharAttribute(attributePlayer, "HelmetBrokenParticles", true)
                --character:SetAttribute("Helmet", false)
                --character:SetAttribute("HelmetBroken", true)
            end
            damage *= helmetMultiplier
        end
    end

    if shield > 0 then
        if shield >= damage then
            shield -= damage
            damage = 0
            damageAppliedToCharacter = false
        else
            damage -= shield
            shield = 0
        end

        setCharAttribute(attributePlayer, "Shield", shield)
    end

    local currHealth = character.Humanoid.Health
    local newHealth

    if RunService:IsClient() then

        local lastRegistered = getCharAttribute(attributePlayer, "LastRegisteredHealth")
        currHealth = lastRegistered or currHealth
        newHealth = currHealth - damage
        killed = newHealth <= 0

        local lastHealth = character.Humanoid.Health - damage
        killed = lastHealth <= 0

        playerHitSoundsClient(character, damager, killed, hitPart)
        setCharAttribute(attributePlayer, "LastRegisteredHealth", lastHealth)
        
        local charPlr = Players:GetPlayerFromCharacter(character)
        if charPlr then
            Events.PlayerGaveDamageBind:Fire(charPlr.Name, damage)
        end
    elseif RunService:IsServer() then
        PlayerAttributes:SetCharacterAttribute(attributePlayer, "Shield", shield)

        newHealth = currHealth - damage
        killed = newHealth <= 0

        if damagedPlayer then
            Events.PlayerReceivedDamageRemote:FireClient(damagedPlayer, Players:GetPlayerFromCharacter(damager).Name, damage)
        end

        character:SetAttribute("Killer", damager.Name)
        if killed then
            character:SetAttribute("WeaponUsedToKill", weaponUsed)
            character:SetAttribute("DiedToHeadshot", isHeadShot)
            -- died through smoke
        end

        if damageAppliedToCharacter then
            character.Humanoid:TakeDamage(damage)
        end

        local t = character.Humanoid:LoadAnimation(character.DamagedAnimation)
        t:Play()
        t.Ended:Once(function()
            t:Destroy()
        end)

        if killed then
            if isBot then
                print('KILLED A BOT')
                task.delay(1, function()
                    PlayerAttributes:ResetCharacterAttributes(attributePlayer)
                end)
            elseif damagedPlayer ~= damagerPlayer then
                PlayerData:IncrementPath(damager, "pstats.kills", 1)
                PlayerData:IncrementPath(character, "pstats.deaths", 1)
            end
        end
    end

    return damage, killed
end

function EvoPlayer:AddHealth(character, amnt, limitAmnt)
    local attributePlayer = false
    pcall(function()
        attributePlayer = Players:GetPlayerFromCharacter(character)
    end)

    attributePlayer = attributePlayer or {Name = "BOT_" .. character.Name}

    local shield = getCharAttribute(attributePlayer, "Shield")
    local health = character.Humanoid.Health
    local healthToAdd = 0
    local shieldToAdd = 0

    if limitAmnt then
        if health + shield >= 150 then
            return
        end

        if health+shield+amnt > 150 then
            amnt = 150 - (health+shield)
        end
    end

    if health == 100 then
        shieldToAdd = amnt
    elseif health + amnt > 100 then
        local h = health + amnt
        shieldToAdd = h - 100
        healthToAdd = amnt - shieldToAdd
    else
        healthToAdd = amnt
    end

    character.Humanoid.Health = health + healthToAdd
    EvoPlayer:SetShield(character, shield + shieldToAdd)
end

--@summary Set the Shield of a player.
function EvoPlayer:SetShield(character, shield): number
    --character:SetAttribute("Shield", shield)
    local plr = Players:GetPlayerFromCharacter(character) or {Name = "BOT_" .. character.Name}
    PlayerAttributes:SetCharacterAttribute(plr, "Shield", shield)
    return shield :: number
end

--@summary Set the Helmet of a player.
function EvoPlayer:SetHelmet(character, helmet): boolean
    --character:SetAttribute("Helmet", helmet)
    local plr = Players:GetPlayerFromCharacter(character) or {Name = "BOT_" .. character.Name}
    PlayerAttributes:SetCharacterAttribute(plr, "Helmet", helmet)
    return helmet :: boolean
end

--@summary Check if player is loaded.
function EvoPlayer:IsLoaded(player)
    return player:GetAttribute("Loaded") or false
end

--@summary Do a function after a player has loaded.
--         If the player is not loaded, This function threads a repeat wait and then calls when loaded.
--         Otherwise, it will just call the function.
function EvoPlayer:DoWhenLoaded(player: Player, callback)
    if not player:GetAttribute("Loaded") then

        if RunService:IsClient() then
            table.insert(EvoPlayer.LoadingFunctions, callback)
        elseif RunService:IsServer() then
            if not EvoPlayer.LoadingFunctions[player.Name] then
                EvoPlayer.LoadingFunctions[player.Name] = {}
            end
            table.insert(EvoPlayer.LoadingFunctions[player.Name], callback)
        end

        return
    end
    return callback()
end

function EvoPlayer:CanDamage(character: Model?)
    --[[local can = GamemodeServiceModule:GetAttribute("CanDamage")
    if can and character then
        can = not character:GetAttribute("SpawnInvincibility")
    end]]
    return true
end

function EvoPlayer:SetSpawnInvincibility(character: Model, enabled: boolean, length: number?)
    local ff = character:FindFirstChild("ForceField")
    if enabled then
        if ff then ff:Destroy() end
        ff = Instance.new("ForceField", character)
        character:SetAttribute("SpawnInvincibility", true)
        if length then
            task.delay(length, function()
                EvoPlayer:SetSpawnInvincibility(character, false)
            end)
        end
    else
        if ff then
            ff:Destroy()
        end
        if character:GetAttribute("SpawnInvincibility") then
            character:SetAttribute("SpawnInvincibility", false)
        end
    end
end

--@summary Kill a player without triggering a PlayerDiedEvent.
function EvoPlayer:ForceKill(player)
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        if player.Character.Humanoid.Health <= 0 then
            return
        end

        Events.ForceKillPlayer:InvokeClient(player)
        player.Character.Humanoid:TakeDamage(10000)
    end
end

--#region Handle Player Death @server

--@tutorial
-- Connect to the PlayerDied Signal:
-- EvoPlayer.PlayerDied:Connect(callback)
-- EvoPlayer.PlayerDied:Once(callback)
-- EvoPlayer.PlayerDied:Disconnect()

if RunService:IsClient() then
    
    -- Local Loading Functions
    local function callLoadingFunctions()
        for _, v in pairs(EvoPlayer.LoadingFunctions) do
            v()
        end
        EvoPlayer.LoadingFunctions = nil
    end

    local player = game.Players.LocalPlayer
    if player:GetAttribute("Loaded") then
        callLoadingFunctions()
    else
        local loadingFunctionsConn
        loadingFunctionsConn = game.Players.LocalPlayer:GetAttributeChangedSignal("Loaded"):Connect(function()
            if player:GetAttribute("Loaded") then
                callLoadingFunctions()
                loadingFunctionsConn:Disconnect()
            end
        end)
    end
    
elseif RunService:IsServer() then

    -- Server loading events function
    local function callLoadingFunctions(player)
        if not EvoPlayer.LoadingFunctions[player.Name] then
            return
        end

        for _, v in pairs(EvoPlayer.LoadingFunctions[player.Name]) do
            v()
        end
        EvoPlayer.LoadingFunctions[player.Name] = nil
    end

    -- Damage Animations
    local function createDamagedAnimation(character)
        local DamagedAnimation = ReplicatedStorage.Services.WeaponService.ServiceAssets.Animations.PlayerHit:Clone()
        DamagedAnimation.Name = "DamagedAnimation"
        DamagedAnimation.Parent = character
    end

    BotServiceModule.Remotes.BotAddedBindable.Event:Connect(function(character)
        createDamagedAnimation(character)
    end)

    Players.PlayerAdded:Connect(function(player)

        -- Handle loading functions if necessary
        local loadingFunctionConn
        loadingFunctionConn = player:GetAttributeChangedSignal("Loaded"):Connect(function()
            if player:GetAttribute("Loaded") then
                callLoadingFunctions(player)
                loadingFunctionConn:Disconnect()
            end
        end)

        player.CharacterAdded:Connect(function(character)
            createDamagedAnimation(character)
        end)
    end)

    --@summary Register a death event received from the client via RemoteEvent -> signal
    --local Signal = require(script:WaitForChild("Signal"))
    --EvoPlayer.PlayerDied = Signal.new()

    -- Authenticate Died Event
    DiedEvent.OnServerEvent:Connect(function(killed, killer)
        --EvoPlayer.PlayerDied:Fire(killed, killer)
        Events.PlayerDiedBindable:Fire(killed, killer)

        -- fire the event for clients
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= killed then
                DiedEvent:FireClient(v, killed, killer)
            end
        end
    end)
end

--#endregion

return EvoPlayer
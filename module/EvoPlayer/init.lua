--[[ Purpose: Centralizing Evostrike Player Functionality ]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DiedEvent = script:WaitForChild("Events").PlayerDiedRemote
--local GamemodeServiceModule = ReplicatedStorage.Services:WaitForChild("GamemodeService")
local Events = script:WaitForChild("Events")
local DiedEvent = Events.PlayerDiedRemote
local PlayerData = require(ReplicatedStorage.Modules.PlayerData)
local BotServiceModule = ReplicatedStorage.Services.BotService
local StoredDamageInformation = require(script:WaitForChild("StoredDamageInformation"))

local EvoPlayer = {}

--@summary Correctly apply damage to the player, checking for shields
function EvoPlayer:TakeDamage(character, damage, damager, weaponUsed)
    if damager and damager.Humanoid.Health <= 0 then return 0 end
    if not EvoPlayer:CanDamage(character) then return 0 end
    local shield = character:GetAttribute("Shield") or 0
    local helmet = character:GetAttribute("Helmet") or false
    local hitPart = character:GetAttribute("lastHitPart") or "Head"
    local destroysHelmet = character:GetAttribute("lastUsedWeaponDestroysHelmet") or false
    local helmetMultiplier = character:GetAttribute("lastUsedWeaponHelmetMultiplier") or 1

    if string.find(string.lower(hitPart), "head") then
        if helmet then
            if destroysHelmet then
                character:SetAttribute("Helmet", false)
                character:SetAttribute("HelmetBroken", true)
            end
            damage *= helmetMultiplier
        end
    end

    absoluteDamage = damage
    if shield > 0 then
        if shield >= damage then -- no damage taken, only apply to shield
            character:SetAttribute("Shield", shield - damage)
            damageAppliedToCharacter = false
        else
            damage -= shield
            character:SetAttribute("Shield", 0)
        end
    end

    if RunService:IsClient() then
        local lastHealth = math.max(0, (character:GetAttribute("LastRegisteredHealth") or character.Humanoid.Health) - damage)
        character:SetAttribute("LastRegisteredHealth", lastHealth)
        killed = lastHealth <= 0

<<<<<<< Updated upstream
    if RunService:IsServer() then
        character.Humanoid:TakeDamage(damage)
=======
        local charPlr = Players:GetPlayerFromCharacter(character)
        Events.PlayerGaveDamageBind:Fire(charPlr.Name, damage)
    else
        Events.PlayerReceivedDamageRemote:FireClient(Players:GetPlayerFromCharacter(character), Players:GetPlayerFromCharacter(damager).Name, damage)

        killed = character.Humanoid.Health - damage <= 0
    end
    

    if RunService:IsServer() then
        character.Humanoid:TakeDamage(damage)
    end

    return damage, killed
end

--@summary Set the Shield of a player.
function EvoPlayer:SetShield(character, shield): number
    character:SetAttribute("Shield", shield)
    return shield :: number
end

--@summary Set the Helmet of a player.
function EvoPlayer:SetHelmet(character, helmet): boolean
    character:SetAttribute("Helmet", helmet)
    return helmet :: boolean
end

--@summary Check if player is loaded.
function EvoPlayer:IsLoaded(player)
    return player:GetAttribute("Loaded") or false
end

--@summary Do a function after a player has loaded.
--         If the player is not loaded, This function threads a repeat wait and then calls when loaded.
--         Otherwise, it will just call the function.
function EvoPlayer:DoWhenLoaded(player, callback)
    if not player:GetAttribute("Loaded") then
        player = player :: Player
        task.spawn(function()
            repeat task.wait() until player:GetAttribute("Loaded")
            callback()
        end)
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

--#region Handle Player Death @server

--@tutorial
-- Connect to the PlayerDied Signal:
-- EvoPlayer.PlayerDied:Connect(callback)
-- EvoPlayer.PlayerDied:Once(callback)
-- EvoPlayer.PlayerDied:Disconnect()

if RunService:IsServer() then

    --@summary Register a death event received from the client via RemoteEvent -> signal
    local Signal = require(script:WaitForChild("Signal"))
    EvoPlayer.PlayerDied = Signal.new()

    DiedEvent.OnServerEvent:Connect(function(killed, killer)
        EvoPlayer.PlayerDied:Fire(killed, killer)

        -- fire the event for clients
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= killed then
                DiedEvent:FireClient(v, killed, killer)
            end
        end
    end)

    --@summary Create the Damaged Remote Event & Animation when a player's character is added.
    --@note    Is all of this connection management necessary? Does CharAdded get removed when a player is removed?
    --         If it is necessary, than there's a good 1GB of memory leakage in this game from just that concept alone
    Players.PlayerAdded:Connect(function(player)
        local charadd
        local plrRemove

        charadd = player.CharacterAdded:Connect(function(character)
            local DamagedAnimation = ReplicatedStorage.Services.WeaponService.ServiceAssets.Animations.PlayerHit:Clone()
            DamagedAnimation.Name = "DamagedAnimation"
            DamagedAnimation.Parent = character
            local DamagedEvent = Instance.new("RemoteEvent", character)
            DamagedEvent.Name = "EvoPlayerDamagedEvent"
        end)

        plrRemove = Players.PlayerRemoving:Connect(function(_rplayer)
            if player == _rplayer then
                charadd:Disconnect()
                plrRemove:Disconnect()
            end
        end)
    end)
end

--#endregion

return EvoPlayer
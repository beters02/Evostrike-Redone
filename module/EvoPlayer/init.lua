--[[ Purpose: Centralizing Evostrike Player Functionality ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local GamemodeServiceModule = ReplicatedStorage.Services:WaitForChild("GamemodeService")

local EvoPlayer = {}

--@summary Correctly apply damage to the player, checking for shields
function EvoPlayer:TakeDamage(character, damage, damager)
    if damager and damager.Humanoid.Health <= 0 then return 0 end
    if not EvoPlayer:CanDamage() then return 0 end
    local shield = character:GetAttribute("Shield") or 0
    local helmet = character:GetAttribute("Helmet") or false
    local hitPart = character:GetAttribute("lastHitPart") or "Head"
    local destroysHelmet = character:GetAttribute("lastUsedWeaponDestroysHelmet") or false
    local helmetMultiplier = character:GetAttribute("lastUsedWeaponHelmetMultiplier") or 1

    if string.match(string.lower(hitPart), "head") then
        if helmet then
            if destroysHelmet then
                character:SetAttribute("Helmet", false)
            end
            damage *= helmetMultiplier
        end
    else
        if shield > 0 then
            if shield >= damage then -- no damage taken, only apply to shield
                character:SetAttribute("Shield", shield - damage)
                return 0
            else
                damage -= shield
                character:SetAttribute("Shield", 0)
            end
        end
    end

    if RunService:IsServer() then
        character.Humanoid:TakeDamage(damage)
    end

    return damage
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

--@summary Do a function after a player has loaded.
--         This function will connect the callback to a :GetAttributeChanged():Once()
--         which replaces the need for ( if not player:GetAttribute("Loaded") then repeat task.wait() )
--         yeah fuck that getAttributeChanged is dogshiut
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

function EvoPlayer:CanDamage()
    return GamemodeServiceModule:GetAttribute("CanDamage")
end

--#region Handle Player Death @server

--@tutorial
-- Connect to the PlayerDied Signal:
-- EvoPlayer.PlayerDied:Connect(callback)
-- EvoPlayer.PlayerDied:Once(callback)
-- EvoPlayer.PlayerDied:Disconnect()

--@summary Register a death event received from the client via RemoteEvent -> signal
if RunService:IsServer() then
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
end

--#endregion

return EvoPlayer
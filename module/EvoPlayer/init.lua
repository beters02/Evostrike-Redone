--[[ Purpose: Centralizing Evostrike Player Functionality ]]

local RunService = game:GetService("RunService")

local EvoPlayer = {}

-- Correctly apply damage to the player, checking for shields
function EvoPlayer:TakeDamage(character, damage)
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

function EvoPlayer:SetShield(character, shield)
    character:SetAttribute("Shield", shield)
    return shield
end

function EvoPlayer:SetHelmet(character, helmet)
    character:SetAttribute("Helmet", helmet)
    return helmet
end

return EvoPlayer
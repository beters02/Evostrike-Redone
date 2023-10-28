-- Strafe is Evostrike's version of "Elo"

-- | Libraries |
local AbilityService = game:GetService("ReplicatedStorage").Services.AbilityService -- Will require all ability modules.

-- | Init Module |
local Strafe = {
    Types = require(script:WaitForChild("Types")),
    Config = require(script:WaitForChild("Config")),
    Gamemodes = {
        ["1v1"] = require(script:WaitForChild("_1v1")),
        ["2v2"] = require(script:WaitForChild("_2v2")),
        ["5v5"] = require(script:WaitForChild("_5v5"))
    }
}

-- | Type Def |
local Types = Strafe.Types

-- | Private Calculation Functions |
local function GetCalcMod(conditions: Types.Conditions)
    return conditions.Won and Strafe.Config.WinModifier or Strafe.Config.LossModifier
end

local function CalcHE(base: Types.Strafe, conditions: Types.Conditions)
    if conditions.HEUsed <= 0 then
        return base
    end

    -- success based on total damage given vs. total damage possible
    local success = conditions.TotalHEDamage / (conditions.HEUsed * require(AbilityService.Ability.HEGrenade).Options.maxDamage)
    if success >= 0.3 then
        base += (Strafe.Config.SuccessHE * GetCalcMod(conditions))
    end
    return base
end

local function CalcFlash(base: Types.Strafe, conditions: Types.Conditions)
    if conditions.FlashUsed <= 0 then
        return base
    end

    -- success based on players hit per flash vs. total flashes used
    local playersFlashedPerFlash = conditions.FlashUsed / conditions.PlayersFlashed
    playersFlashedPerFlash = (playersFlashedPerFlash/Strafe.Config.RequiredPlayersFlashedPerFlashForSuccess)
    if playersFlashedPerFlash > 0 then
        base += (playersFlashedPerFlash * GetCalcMod(conditions))
    end
    return base
end

local function CalcMolly(base: Types.Strafe, conditions: Types.Conditions)
    if conditions.MollyUsed <= 0 then
        return base
    end

    -- success based on total damage given vs. total damage possible
    local success = conditions.TotalMollyDamage / (conditions.MollyUsed * require(AbilityService.Ability.HEGrenade).Options.maxDamage)
    if success >= 0.3 then
        base += (Strafe.Config.SuccessHE * GetCalcMod(conditions))
    end
    return base
end

local function CalcAccuracy(base: Types.Strafe, conditions: Types.Conditions)
    -- only grant accuracy bonus if 5 or more shots were taken
    if conditions.ShotsTaken == 0 or (conditions.ShotsTaken == conditions.ShotsHit and conditions.ShotsHit <= 5) then
        return base
    end
    local acc = conditions.ShotsHit / conditions.ShotsTaken
    if acc >= 0.5 then
        -- highest accuracy achievement = 0.7
        base += (5*(acc*10/7) * GetCalcMod(conditions))
    end
    return base
end

local function CalcRoundCloseness(base: Types.Strafe, conditions: Types.Conditions)
    local add = Strafe.Config.BaseGameNotCloseOrStomp
    if math.abs(conditions.RoundsWon - conditions.RoundsLost) <= 3 then
        -- even match, both players receive equal closeness bonus
        add = Strafe.Config.BaseGameCloseAdd
    elseif math.abs(conditions.RoundsWon - conditions.RoundsLost) >= (conditions.TotalRoundsNeedToWinInGamemode - 2) then
        add = conditions.Won and Strafe.Config.BaseGameStompAdd or -Strafe.Config.BaseGameStompRemove
    end
    return base + add
end

-- | Module Functions |
function Strafe:CalculatePostMatchStrafe(conditions: Types.Conditions): Types.Strafe
    local strafe = conditions.Won and Strafe.Config.BaseAdd or Strafe.Config.BaseRemove
    strafe = CalcHE(strafe, conditions)
    strafe = CalcFlash(strafe, conditions)
    strafe = CalcMolly(strafe, conditions)
    strafe = CalcAccuracy(strafe, conditions)
    strafe = CalcRoundCloseness(strafe, conditions)
    return strafe
end

return Strafe
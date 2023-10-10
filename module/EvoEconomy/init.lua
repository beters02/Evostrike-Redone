local RunService = game:GetService("RunService")
if RunService:IsClient() then
    return require(script:WaitForChild("Client"))
end

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

export type Currency = "PremiumCredits" | "StrafeCoins" | "XP"

local Economy = {}

function Economy:Get(player: Player, currency: Currency)
    return PlayerData:GetPath(player, "economy." .. _currToDataKey(currency))
end

function Economy:Increment(player: Player, currency: Currency, amnt: number)
    local currentAmount = Economy:Get(player, currency)
    return _Set(player, currency, currentAmount + amnt)
end

function Economy:Decrement(player: Player, currency: Currency, amnt: number)
    local currentAmount = Economy:Get(player, currency)
    assert(currentAmount - amnt > 0, "Cannot decrement past 0. " .. tostring(currentAmount))
    return _Set(player, currency, currentAmount - amnt)
end

function Economy:Save(player)
    return PlayerData:Save(player)
end

--[[]]
function Economy:ProcessTransaction(player: Player, currency: Currency, amount: number)
    local current = Economy:Get(player, "StrafeCoins")
    if current - amount < 0 then
        return false, "Not enough " .. tostring(currency) .. "."
    end

    Economy:Decrement(player, currency, amount)

    local success, result = pcall(function()
        PlayerData:SaveWithRetry(player, 5, true)
    end)
    if not success then
        return false, "Could not save playerdata. " .. tostring(result)
    end
    
    print("Removed " .. tostring(amount) .. " " .. tostring(currency) .. " from player " .. player.Name)
    return true
end

--[[Private]]
function _Set(player: Player, currency: Currency, new: number)
    return PlayerData:SetPath(player, "economy." .. _currToDataKey(currency), new)
end

--[[Util]]
function _currToDataKey(currency: Currency)
    return (currency == "StrafeCoins" and "strafeCoins" or false) or (currency == "PremiumCredits" and "premiumCredits" or false) or "xp"
end

return Economy
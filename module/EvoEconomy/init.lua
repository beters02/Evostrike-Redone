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
    return _Set(player, currency, currentAmount - amnt)
end

function Economy:Save(player)
    return PlayerData:Save(player)
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
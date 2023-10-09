local RunService = game:GetService("RunService")
if RunService:IsServer() then return end

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Client = {}

function Client:Get(currency: "StrafeCoins" | "PremiumCredits" | "XP")
    local dataKey = (currency == "StrafeCoins" and "strafeCoins" or false) or (currency == "PremiumCredits" and "premiumCredits" or false) or "xp"
    return PlayerData:GetPath("economy." .. dataKey)
end

return Client
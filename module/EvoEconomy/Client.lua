local RunService = game:GetService("RunService")
if RunService:IsServer() then return end

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Client = {}

function Client:Get(currency: "StrafeCoins" | "PremiumCredits")
    local dataKey = currency == "StrafeCoins" and "strafeCoins" or "premiumCredits"
    return PlayerData:GetPath("economy." .. dataKey)
end

return Client
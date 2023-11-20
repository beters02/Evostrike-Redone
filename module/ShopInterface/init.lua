-- Evostrike ShopScript Client Interface Module

local Shop = {}
local Events = script:WaitForChild("Events")
local Shared = require(script:WaitForChild("Shared"))

if game:GetService("RunService"):IsServer() then
    return require(script:WaitForChild("Server"))
end

function Shop:PurchaseItem(item: Shared.TShopItem, purchaseType: "StrafeCoins" | "PremiumCredits")
    return Events.rf_AttemptItemPurchase:InvokeServer(purchaseType, item)
end

function Shop:HasKey(caseName)
    return Events.rf_HasKey:InvokeServer(caseName)
end

function Shop:GetItemPrice(item)
    return Events.rf_GetItemPrice:InvokeServer(item)
end

function Shop:OpenCase(caseName)
    return Events.rf_OpenCase:InvokeServer(caseName)
end

return Shop
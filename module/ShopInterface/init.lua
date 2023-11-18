-- Evostrike ShopScript Client Interface Module

local Shop = {}
local Events = script:WaitForChild("Events")
local Shared = require(script:WaitForChild("Shared"))

function Shop:PurchaseItem(item: Shared.TShopItem, purchaseType: "StrafeCoins" | "PremiumCredits")
    return Events.rf_AttemptItemPurchase:InvokeServer(purchaseType, item)
end

function Shop:HasKey(caseName)
    Events.rf_HasKey:InvokeServer(caseName)
end

function Shop:UseKey(caseName)
    Events.rf_UseKey:InvokeServer(caseName)
end

function Shop:GetItemPrice(item)
    return Events.rf_GetItemPrice:InvokeServer(item)
end

return Shop
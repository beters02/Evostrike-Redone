local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local ClientInterface = ReplicatedStorage.Modules.ShopInterface
local Events = ClientInterface.Events
local Shared = require(ClientInterface.Shared)
local Items = require(script:WaitForChild("Items"))
local Strings = require(Framework.Module.lib.fc_strings)
local PlayerData = require(Framework.Module.PlayerData)
local Admins = require(game:GetService("ServerStorage").Stored.AdminIDs)

local Shop = {}
local RemoteFunctions = {}

Shop = {
    parseItemString = function(item: Shared.TShopItem)
        local split = string.split(item, "_")
        local returnObject = {
            insert_type = "table",
            path = split[2],
            price_sc = 0,
            price_pc = 0,
            item_type = split[1],
            model = split[2],
            skin = split[3],
            knifeWrap = split[4]
        }

        if split[1] == "skin" then
            local weapon = split[2]
            local skin = split[3]
            if weapon == "knife" then
                skin = split[3] .. "_" .. split[4]
            end

            local pd = Strings.convertPathToInstance("Skins." .. weapon .. "." .. skin, Items)
            returnObject.price_pc = pd.buy_pc
            returnObject.price_sc = pd.buy_sc
            returnObject.path = weapon .. "_" .. skin
        else
            local pd = Strings.convertPathToInstance("Cases." .. returnObject.model, Items)
            returnObject.price_pc = pd.buy_pc
            returnObject.price_sc = pd.buy_sc
            returnObject.path = "case_" .. returnObject.model
        end

        return returnObject
    end,
    canAffordItem = function(player, purchaseType: "StrafeCoins" | "PremiumCredits", item)
        if purchaseType ~= "StrafeCoins" and purchaseType ~= "PremiumCredits" then
            error("Invalid PurchaseType!")
        end
    
        local pd = PlayerData:Get(player)
        local currAmnt = purchaseType == "StrafeCoins" and pd.economy.strafeCoins or pd.economy.premiumCredits
    
        local p = RemoteFunctions.GetItemPrice(false, item)
        p = purchaseType == "StrafeCoins" and p.sc or p.pc
        return currAmnt >= p, p
    end
}

Shop.PurchaseItem = function(player, purchaseType, item)
    local canPurchase = Shop.canAffordItem(player, purchaseType, item)
    if canPurchase then
        local pathStr = purchaseType == "StrafeCoins" and "strafeCoins" or "premiumCredits"

        local priceData = Shop.parseItemString(item)
        local price = pathStr == "strafeCoins" and "price_sc" or "price_pc"
        price = priceData[price]

        if priceData.insert_type == "table" then
            local inventoryStr = priceData.item_type == "case" and "inventory.case" or "inventory.skin"
            PlayerData:TableInsert(player, inventoryStr, priceData.path)
        else
            PlayerData:IncrementPath(player, "economy.pc", priceData.path)
        end

        PlayerData:DecrementPath(player, "economy." .. pathStr, price)
        PlayerData:Save(player)
        return true
    end
    return false
end

-- RemoteFunctions (RemoteFunctions in ShopInterface.Events will correspond to functions via name. ["rf_GetItemPrice"])
RemoteFunctions = {
    GetItemPrice = function(_, item)
        local i = Shop.parseItemString(item)
        return {sc = i.price_sc, pc = i.price_pc, parsed = i}
    end,
    CanAffordItem = Shop.canAffordItem,
    AttemptItemPurchase = Shop.PurchaseItem
}

RemoteFunctions.HasKey = function(player, caseName) -- Returns Key Inventory Index or False
    local keyInventory = PlayerData:GetPath(player, "inventory.key")
    for i, v in pairs(keyInventory) do
        if string.match(v, caseName) then
            return i
        end
    end
end

RemoteFunctions.UseKey = function(player, caseName)
    local keyIndex = false
    local keyInventory = PlayerData:GetPath(player, "inventory.key")
    for i, v in pairs(keyInventory) do
        if string.match(v, caseName) then
            keyIndex = i
            break
        end
    end

    if not keyIndex then return false end
    table.remove(keyInventory, keyIndex)
    PlayerData:SetPath(player, "inventory.key", keyInventory)
    PlayerData:Save(player)
end

-- INIT
for _, v in pairs(Events:GetChildren()) do
    if string.match(v.Name, "rf_") then
        v.OnServerInvoke = RemoteFunctions[v.Name:gsub("rf_", "")]
    end
end

Events.c_AddStrafeCoins.OnServerInvoke = function(sndPlr, addPlr, amount)
    if Admins:IsAdmin(sndPlr) then
        return pcall(function()
            PlayerData:IncrementPath(addPlr, "economy.strafeCoins", amount)
            PlayerData:Save(addPlr)
        end)
    end
    return false, "Sender is not Admin"
end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local ClientInterface = ReplicatedStorage.Modules.ShopInterface
local Events = ClientInterface.Events
local Shared = require(ClientInterface.Shared)
local Strings = require(Framework.Module.lib.fc_strings)
local Tables = require(Framework.Module.lib.fc_tables)
local PlayerData = require(Framework.Module.PlayerData)
local Admins = require(ServerStorage.Stored.AdminIDs)
local Cases = require(ServerStorage.Stored.Cases)
local Skins = require(ServerStorage.Stored.Skins)
local Keys = require(ServerStorage.Stored.Keys)

local Shop = {}
local RemoteFunctions = {}

-- [[ SHOP PRIVATE ]]
Shop = {
    parseItemString = function(item: Shared.TShopItem)
        local split = string.split(item, "_")
        local returnObject

        if split[1] == "skin" then
            local skin = string.gsub(item, "skin_", "")
            returnObject = Tables.clone(Skins.GetSkinFromString(skin))
            returnObject.item_type = "skin"
            returnObject.insert_type = "table"
            returnObject.path = skin
            returnObject.inventoryKey = skin
        elseif split[1] == "case" then
            returnObject = Tables.clone(Cases.Cases[split[2]])
            returnObject.item_type = "case"
            returnObject.insert_type = "table"
            returnObject.path = "case_" .. split[2]
            returnObject.inventoryKey = returnObject.path
        elseif split[1] == "key" then
            returnObject = Tables.clone(Keys[split[2]])
            returnObject.item_type = "key"
            returnObject.insert_type = "table"
            returnObject.path = "key_" .. split[2]
            returnObject.inventoryKey = returnObject.path
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

-- [[ SHOP PUBLIC ]]
Shop.PurchaseItem = function(player, purchaseType, item)
    local canPurchase = Shop.canAffordItem(player, purchaseType, item)
    if canPurchase then
        local pathStr = purchaseType == "StrafeCoins" and "strafeCoins" or "premiumCredits"

        local priceData = Shop.parseItemString(item)
        local price = pathStr == "strafeCoins" and "price_sc" or "price_pc"
        price = priceData[price]

        if priceData.insert_type == "table" then
            local inventoryStr = "inventory." .. priceData.item_type
            PlayerData:TableInsert(player, inventoryStr, priceData.inventoryKey)
        else -- this is for when players want to buy premiumCredits
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
            return i, keyInventory
        end
    end
    return false
end

RemoteFunctions.HasCase = function(player, caseName)
    local caseInventory = PlayerData:GetPath(player, "inventory.case")
    for i, v in pairs(caseInventory) do
        if string.match(v, caseName) then
            return i, caseInventory
        end
    end
    return false
end

RemoteFunctions.OpenCase = function(player, caseName)
    local caseIndex, caseInventory = RemoteFunctions.HasCase(player, caseName)
    local keyIndex, keyInventory = RemoteFunctions.HasKey(player, caseName)
    if not caseIndex or not keyIndex then
        return false
    end

    --local openedItem, potentialItems = EvoCases:Open(caseName)
    local openedSkin, potentialSkins = Cases.OpenCase(caseName)
    assert(openedSkin and potentialSkins, "Could not get Opened Case Item from server. Credits were not spent.")

    print(caseInventory)
    table.remove(caseInventory, caseIndex)
    print(caseInventory)

    table.remove(keyInventory, keyIndex)
    PlayerData:SetPath(player, "inventory.case", caseInventory)
    PlayerData:SetPath(player, "inventory.key", keyInventory)
    print("Successfully removed Case and Key from player's inventory for Case Opening.")

    PlayerData:TableInsert(player, "inventory.skin", openedSkin.inventoryKey)
    print("Successfully added received Case Item to player's inventory.")

    PlayerData:Save(player)

    return openedSkin, potentialSkins
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
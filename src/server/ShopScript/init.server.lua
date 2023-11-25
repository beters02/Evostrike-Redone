local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local ClientInterface = ReplicatedStorage.Modules.ShopInterface
local Events = ClientInterface.Events
local Strings = require(Framework.Module.lib.fc_strings)
local Tables = require(Framework.Module.lib.fc_tables)
local PlayerData = require(Framework.Module.PlayerData)
local Admins = require(ServerStorage.Stored.AdminIDs)
local Cases = require(ServerStorage.Stored.Cases)
local Skins = require(ServerStorage.Stored.Skins)
local Keys = require(ServerStorage.Stored.Keys)
local HTTPService = game:GetService("HttpService")

local Shop = {}
local RemoteFunctions = {}

function init()
    RemoteFunctions = {
        GetShopItemFromString = Shop.parseItemString,
        CanAffordItem = Shop.canAffordItem,
        AttemptItemPurchase = Shop.PurchaseItem,
        HasKey = Shop.HasKey,
        HasCase = Shop.HasCase,
        OpenCase = Shop.OpenCase,
        GetItemPrice = function(_, itemStr) return Shop.parseItemString(itemStr) end,
        AttemptItemSell = Shop.SellItem
    }
    
    for _, v in pairs(Events:GetChildren()) do
        if string.match(v.Name, "rf_") then
            v.OnServerInvoke = RemoteFunctions[v.Name:gsub("rf_", "")]
        end
    end
    
    --TEMP
    Events.c_AddStrafeCoins.OnServerInvoke = function(sndPlr, addPlr, amount)
        if Admins:IsAdmin(sndPlr) then
            return pcall(function()
                PlayerData:IncrementPath(addPlr, "economy.strafeCoins", amount)
                PlayerData:Save(addPlr)
            end)
        end
        return false, "Sender is not Admin"
    end

    Events.c_AddInventoryItem.OnServerInvoke = function(sndPlr, addPlr, item)
        if Admins:IsAdmin(sndPlr) then
            return pcall(function()
                PlayerData:TableInsert(addPlr, "ownedItems.skin", item .. "_" .. game:GetService("HttpService"):GenerateGUID(false))
                PlayerData:Save(addPlr)
            end)
        end
        return false, "Sender is not admin."
    end
end

-- [[ SHOP PRIVATE ]]
function Shop.parseItemString(item: string)
    local split = item:split("_")
    local returnObject = {}
    if split[1] == "skin" then
        local skin = string.gsub(item, "skin_", "")
        returnObject = Tables.clone(Skins.GetSkinFromString(skin))
        returnObject.item_type = "skin"
        returnObject.insert_type = "table"
        returnObject.inventory_key = skin
    elseif split[1] == "case" then
        returnObject = Tables.clone(Cases.Cases[split[2]])
        returnObject.item_type = "case"
        returnObject.insert_type = "table"
        returnObject.inventory_key = split[2]
    elseif split[1] == "key" then
        returnObject = Tables.clone(Keys[split[2]])
        returnObject.item_type = "key"
        returnObject.insert_type = "table"
        returnObject.inventory_key = split[2]
    end
    return returnObject
end

function Shop.canAffordItem(player, purchaseType: "StrafeCoins" | "PremiumCredits", item)
    if purchaseType ~= "StrafeCoins" and purchaseType ~= "PremiumCredits" then
        error("Invalid PurchaseType!")
    end

    local pd = PlayerData:Get(player)
    local currAmnt = purchaseType == "StrafeCoins" and pd.economy.strafeCoins or pd.economy.premiumCredits

    local shopSkin = Shop.parseItemString(item)
    local price = purchaseType == "StrafeCoins" and shopSkin.price_sc or shopSkin.price_pc
    return currAmnt >= price, price, shopSkin
end

-- [[ SHOP PUBLIC ]]
function Shop.PurchaseItem(player, item, purchaseType)
    local ptkey = purchaseType == "StrafeCoins" and "strafeCoins" or "premiumCredits"
    local canPurchase, price, shopItem = Shop.canAffordItem(player, purchaseType, item)
    if canPurchase then
        local insertKey = shopItem.inventory_key
        if shopItem.item_type == "skin" then
            insertKey = insertKey .. "_" .. HTTPService:GenerateGUID(false)
            if shopItem.weapon ~= "knife" then
                insertKey = shopItem.weapon .. "_" .. insertKey
            end
        end
        PlayerData:TableInsert(player, "ownedItems." .. shopItem.item_type, insertKey)
        PlayerData:DecrementPath(player, "economy." .. ptkey, price)
        PlayerData:Save(player)
        return true
    end
    return false
end

function Shop.SellItem(player, shopItemStr, inventoryItemStr)
    local shopSkin = Shop.parseItemString(shopItemStr)
    local skinInventory = PlayerData:GetPath(player, "ownedItems." .. shopSkin.item_type)

    local hasSkinIndex = false
    for i, v in pairs(skinInventory) do
        if v == inventoryItemStr then
            hasSkinIndex = i
            break
        end
    end
    if not hasSkinIndex then
        warn("Player does not have item to sell. " .. tostring(inventoryItemStr))
        return false
    end

    table.remove(skinInventory, hasSkinIndex)
    PlayerData:SetPath(player, "ownedItems." .. shopSkin.item_type, skinInventory)
    PlayerData:IncrementPath(player, "economy.strafeCoins", shopSkin.sell_sc or (shopSkin.price_sc*0.75))
    PlayerData:Save(player)
    return true
end

function Shop.HasKey(player, caseName)
    local keyInventory = PlayerData:GetPath(player, "ownedItems.key")
    for i, v in pairs(keyInventory) do
        if string.match(v, caseName) then
            return i, keyInventory
        end
    end
    return false
end

function Shop.HasCase(player, caseName)
    local caseInventory = PlayerData:GetPath(player, "ownedItems.case")
    for i, v in pairs(caseInventory) do
        if string.match(v, caseName) then
            return i, caseInventory
        end
    end
    return false
end

function Shop.OpenCase(player, caseName)
    local caseIndex, caseInventory = RemoteFunctions.HasCase(player, caseName)
    local keyIndex, keyInventory = RemoteFunctions.HasKey(player, caseName)
    if not caseIndex or not keyIndex then
        return false
    end

    --local openedItem, potentialItems = EvoCases:Open(caseName)
    local openedSkin, potentialSkins = Cases.OpenCase(caseName)
    assert(openedSkin and potentialSkins, "Could not get Opened Case Item from server. Credits were not spent.")

    table.remove(caseInventory, caseIndex)
    table.remove(keyInventory, keyIndex)
    PlayerData:SetPath(player, "ownedItems.case", caseInventory)
    PlayerData:SetPath(player, "ownedItems.key", keyInventory)
    print("Successfully removed Case and Key from player's inventory for Case Opening.")

    PlayerData:TableInsert(player, "ownedItems.skin", openedSkin .. "_" .. HTTPService:GenerateGUID(false))
    print("Successfully added received Case Item to player's inventory.")

    PlayerData:Save(player)
    return openedSkin, potentialSkins
end

--this is for when players want to buy premiumCredits
--[[if priceData.insert_type == "table" then
    PlayerData:TableInsert(player, inventoryStr, priceData.inventoryKey)
else
    PlayerData:IncrementPath(player, "economy.pc", priceData.path)
end]]

init()
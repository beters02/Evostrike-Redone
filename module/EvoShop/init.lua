local RunService = game:GetService("RunService")
-- Evostrike Shop Module
if RunService:IsClient() then
    return(require(script:WaitForChild("Client")))
end

local EvoEconomy = require(script.Parent:WaitForChild("EvoEconomy"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Admins = require(game:GetService("ServerStorage"):WaitForChild("Stored"):WaitForChild("AdminIDs"))

local Shop = {}
local Private = {}
Shop.Items = require(script:WaitForChild("Items"))

--

function Shop:AttemptItemPurchase(player: Player, PurchaseType: "StrafeCoins" | "PremiumCredits", ItemType: "Case" | "Key" | "Skin", Item: string)
    local item = Shop.Items[ItemType][Item]
    local priceIndex = PurchaseType == "StrafeCoins" and "buy_sc" or "buy_pc"
    assert(item, "This item does not exist. " .. tostring(Item) .. ": " .. tostring(ItemType))
    assert(item[priceIndex], "You cannot buy this item with this currency. " .. tostring(PurchaseType))
    priceIndex = item[priceIndex]

    local success, errMsg = EvoEconomy:ProcessTransaction(player, PurchaseType, priceIndex)
    assert(success, errMsg)

    return Private["Add" .. ItemType](player, Item)
end

function Private.AddCase(player, item)
    local inv = PlayerData:GetPath(player, "inventory.case")
    local _to = tick() + 5
    while not inv and tick() < _to do
        inv = PlayerData:GetPath(player, "inventory.case")
        task.wait(0.5)
    end
    assert(inv, "Could not get Player's Case Inventory. " .. tostring(player.Name))

    table.insert(inv, item)
    PlayerData:SetPath(player, "inventory.case", inv)
    PlayerData:SaveWithRetry(player, 5)
    print("Added " .. tostring(item) .. " to " .. player.Name .. "'s Inventory.")
    return true
end

function Private.AddKey(player, item)
    return Shop:AddCase(player, item)
end

function AddSkin(player, item)
    
end

game.ReplicatedStorage.Remotes.AddCase.OnServerEvent:Connect(function(player)
    if not Admins:IsAdmin(player) then
        return
    end

    Private.AddCase(player, "WeaponCase1")
    Private.AddKey(player, "WeaponCase1")
end)

return Shop
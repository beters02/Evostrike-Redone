local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local Tables = require(Framework.Module.lib.fc_tables)

local ShopInterface = require(Framework.Module.ShopInterface)
local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local AttemptItemPurchaseGui = ShopAssets:WaitForChild("AttemptItemPurchase")
local ItemList = require(script.Parent.Parent.components.ItemList)

local Shop = {}
--TODO: change all Shop-Personal functions to be a script function rather than a module function.

-- [[ PAGE CLASS FUNCTIONS ]]
function Shop:init()
    self = setmetatable(Shop, self)
    self.Player = game.Players.LocalPlayer
    self.button_connections = {}

    self.itemDisplayFrame = self.Location:WaitForChild("ItemDisplayFrame")
    self.itemDisplayVar = {active = false, purchaseActive = false, purchaseProcessing = false}
    self.itemDisplayConns = {}

    -- ItemLists
    self.itemLists = {}
    for _, itemListFrame in pairs(self.Location:GetChildren()) do
        if itemListFrame:IsA("Frame") and string.match(itemListFrame.Name, "ItemList_") then
            local OItemList = ItemList.init(self, itemListFrame)
            self.itemLists[itemListFrame.Name] = OItemList
        end
    end

    self.core_connections = {
        sc = PlayerData:PathValueChanged("economy.strafeCoins", function(new)
            self:UpdateEconomy(new)
        end),
        pc = PlayerData:PathValueChanged("economy.premiumCredits", function(new)
            self:UpdateEconomy(false, new)
        end)
    }

    local owned = self.Location:WaitForChild("OwnedFrame")
    self.pcLabel = owned:WaitForChild("PremiumCreditAmountLabel")
    self.scLabel = owned:WaitForChild("StrafeCoinAmountLabel")
    
    local pd = PlayerData:GetKey("economy")
    self:UpdateEconomy(pd.strafeCoins, pd.premiumCredits)
    return self
end

function Shop:Open()
    self:ConnectButtons()
    self:OpenAnimations()
    self:TogglePages(true)
end

function Shop:Close()
    self:DisconnectButtons()
    self:CloseItemDisplay()
    self.Location.Visible = false
    self:TogglePages()
end

--

function Shop:ConnectButtons()
    self.button_connections.skins = self.Location.SkinsButton.MouseButton1Click:Connect(function()
        self:OpenSkinsPage()
    end)
    self.button_connections.collections = self.Location.CollectionsButton.MouseButton1Click:Connect(function()
        self:OpenCollectionsPage()
    end)
    self.button_connections.cases = self.Location.CasesButton.MouseButton1Click:Connect(function()
        self:OpenCasesPage()
    end)
end

function Shop:DisconnectButtons()
    self.button_connections.skins:Disconnect()
    self.button_connections.collections:Disconnect()
    self.button_connections.cases:Disconnect()
end

-- [[ COLLECTIONS / SKINS / CASES PAGE ]]
function Shop:OpenSkinsPage(async)
    if not async and self.openItemList == "Skins" then
        return
    end
    self.openItemList = "Skins"

    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(29, 42, 59)
    self.Location.CollectionsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.itemLists.ItemList_Skins:Enable()
    self.itemLists.ItemList_Cases:Disable()
    self.itemLists.ItemList_Keys:Disable()
    self.itemLists.ItemList_Collections:Disable()
end

function Shop:OpenCollectionsPage(async)
    if not async and self.openItemList == "Collections" then
        return
    end
    self.openItemList = "Collections"

    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.CollectionsButton.BackgroundColor3 = Color3.fromRGB(29, 42, 59)
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.itemLists.ItemList_Skins:Disable()
    self.itemLists.ItemList_Cases:Disable()
    self.itemLists.ItemList_Keys:Disable()
    self.itemLists.ItemList_Collections:Enable()
end

function Shop:OpenCasesPage(async)
    if not async and self.openItemList == "Cases" then
        return
    end
    self.openItemList = "Cases"

    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.CollectionsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(29, 42, 59)
    self.itemLists.ItemList_Cases:Enable()
    self.itemLists.ItemList_Keys:Enable()
    self.itemLists.ItemList_Skins:Disable()
    self.itemLists.ItemList_Collections:Disable()
end

-- Toggle All Pages On/Off
function Shop:TogglePages(toggle)
    if toggle then
        self.openItemList = self.openItemList or "Collections"
        if self.openItemList == "Collections" then
            self:OpenCollectionsPage(true)
        elseif self.openItemList == "Skins" then
            self:OpenSkinsPage(true)
        else
            self:OpenCasesPage(true)
        end
        self.Location.SkinsButton.Visible = true
        self.Location.CollectionsButton.Visible = true
        self.Location.CasesButton.Visible = true
    else
        self.itemLists.ItemList_Skins:Disable()
        self.itemLists.ItemList_Cases:Disable()
        self.itemLists.ItemList_Keys:Disable()
        self.itemLists.ItemList_Collections:Disable()
        self.Location.SkinsButton.Visible = false
        self.Location.CollectionsButton.Visible = false
        self.Location.CasesButton.Visible = false
    end
end

-- [[ ITEM DISPLAY ]]
function Shop:OpenItemDisplay(item, itemDisplayName)
    if self.itemDisplayVar.active then return end
    self.itemDisplayVar.active = true -- turned off in CloseItemDisplay()

    local price = ShopInterface:GetItemPrice(item)
    local itemType = price.parsed.item_type
    itemDisplayName = itemDisplayName or price.parsed.name

    self.itemDisplayFrame.Price_PC.Text = tostring(price.pc)
    self.itemDisplayFrame.Price_SC.Text = tostring(price.sc)

    if itemType == "case" or itemType == "key" then
        self.itemDisplayFrame.CaseDisplay.Visible = true
        self.itemDisplayFrame.ItemDisplayImageLabel.Visible = false
        self.itemDisplayFrame.ItemName.Text = string.upper(itemDisplayName)
    else
        local skin = price.parsed

        self.itemDisplayFrame.CaseDisplay.Visible = false
        local imgLabel = self.itemDisplayFrame.ItemDisplayImageLabel
        imgLabel.Image = self:GetSkinDisplayImageID(skin.weapon, skin.index) or imgLabel.Image
        self.itemDisplayFrame.ItemDisplayImageLabel.Visible = true
        self.itemDisplayFrame.ItemName.Text = tostring(skin.index)
    end

    self.itemDisplayConns.MainButton = self.itemDisplayFrame.MainButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.purchaseActive then
            return
        end
        self.itemDisplayVar.purchaseActive = true -- turned off in itemDisplayDisconectMainClicked()
        self:_MainClickedItemDisplay(item, itemType, price)
    end)

    self.itemDisplayConns.BackButton = self.itemDisplayFrame.BackButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.purchaseActive then
            return
        end
        self:CloseItemDisplay()
    end)

    self:TogglePages()
    self.itemDisplayFrame.Visible = true
end

function Shop:CloseItemDisplay()
    for _, v in pairs(CollectionService:GetTagged("CloseItemDisplay")) do
        v:Destroy()
    end
    for _, v in pairs(self.itemDisplayConns) do
        v:Disconnect()
        v = false
    end
    self.itemDisplayVar.purchaseActive = false
    self.itemDisplayVar.active = false
    self.itemDisplayFrame.Visible = false
    self:TogglePages(true)
end

function Shop:_MainClickedItemDisplay(item, itemType, price)
    local confirmGui = AttemptItemPurchaseGui:Clone()
    local confirmFrame = confirmGui:WaitForChild("Frame")
    CollectionService:AddTag(confirmGui, "CloseItemDisplay")

    local pcAcceptButton = confirmFrame:WaitForChild("PCAcceptButton")
    local scAcceptButton = confirmFrame:WaitForChild("SCAcceptButton")
    local declineButton = confirmFrame:WaitForChild("DeclineButton")
    local skinLabel = confirmFrame:WaitForChild("SkinLabel")
    local weaponLabel = confirmFrame:WaitForChild("WeaponLabel")
    local caseLabel = confirmFrame:WaitForChild("CaseLabel")

    pcAcceptButton.Text = tostring(price.pc) .. " PC"
    scAcceptButton.Text = tostring(price.sc) .. " SC"
    if itemType == "case" or itemType == "key" then
        skinLabel.Visible = false
        weaponLabel.Visible = false
        caseLabel.Text = string.upper(tostring(price.parsed.name))
        caseLabel.Visible = true
    else
        skinLabel.Text = string.upper(tostring(price.parsed.name))
        weaponLabel.Text = string.upper(tostring(price.parsed.weapon))
        caseLabel.Visible = false
    end
    local conns = {}
    local function otherDisconnect(index)
        for i, v in pairs(conns) do
            if index and i == index then
                continue
            end
            v:Disconnect()
        end
    end

    local function selfDisconnect(index)
        task.spawn(function()
            conns[index]:Disconnect()
        end)
    end
    
    conns[1] = pcAcceptButton.MouseButton1Click:Once(function()
        if self.itemDisplayVar.purchaseProcessing then
            return
        end
        self.itemDisplayVar.purchaseProcessing = true
        otherDisconnect(1)
        itemDisplayPurchaseItem(self, item, "PremiumCredits", price.parsed)
        confirmGui:Destroy()
        selfDisconnect(1)
        self:CloseItemDisplay()
        self.itemDisplayVar.purchaseProcessing = false
        self.itemDisplayVar.purchaseActive = false
        conns = nil
    end)

    conns[2] = scAcceptButton.MouseButton1Click:Once(function()
        if self.itemDisplayVar.purchaseProcessing then
            return
        end
        self.itemDisplayVar.purchaseProcessing = true
        otherDisconnect(2)
        itemDisplayPurchaseItem(self, item, "StrafeCoins", price.parsed)
        confirmGui:Destroy()
        selfDisconnect(2)
        self:CloseItemDisplay()
        self.itemDisplayVar.purchaseProcessing = false
        self.itemDisplayVar.purchaseActive = false
        conns = nil
    end)

    conns[3] = declineButton.MouseButton1Click:Connect(function()
        otherDisconnect(3)
        confirmGui:Destroy()
        selfDisconnect(3)
        self:CloseItemDisplay()
        conns = nil
    end)

    confirmGui.Parent = game.Players.LocalPlayer.PlayerGui
end

function itemDisplayPurchaseItem(self, item, purchaseType, parsedItem)
    if ShopInterface:PurchaseItem(item, purchaseType) then
        task.delay(0.5, function()
            self:FindPage("Inventory"):Update(true)
        end)
        Popup.burst("Successfully bought item! " .. tostring(parsedItem.name), 3)
        return true
    else
        Popup.burst("Could not buy item " .. tostring(parsedItem.name), 3)
        return false
    end
end

-- [[ UTIL ]]
function Shop:GetSkinDisplayImageID(weapon, skin): string
    return ReplicatedStorage:WaitForChild("Assets").Shop.SkinImages[skin][weapon].Image
end

function Shop:UpdateEconomy(sc: number?, pc: number?)
    if sc then
        self.scLabel.Text = tostring(sc)
    end
    if pc then
        self.pcLabel.Text = tostring(pc)
    end
end

return Shop
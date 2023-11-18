local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local Tables = require(Framework.Module.lib.fc_tables)

local ShopInterface = require(Framework.Module.ShopInterface)
local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local AttemptItemPurchaseGui = ShopAssets:WaitForChild("AttemptItemPurchase")

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

    self.itemListDefaultFrame = self.Location.ItemListContainer_Skins.MainList
    self.itemListFrame = self.itemListDefaultFrame
    self.itemListConns = {}
    self.itemListVar = {OpenListName = "MainList"}

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
    self:OpenAnimations()
    ConnectButtons(self)
end

function Shop:Close()
    self:CloseItemDisplay()
    self:CloseItemList()
    self.Location.Visible = false
    DisconnectButtons(self)
end

--[[ BUTTONS ]]
function ConnectButtons(self)
    -- [[ Connect Case Buttons]]
    for _, itemButton in pairs(self.Location.ItemListContainer_Cases.MainListFrame:GetChildren()) do
        if itemButton:IsA("TextButton") and not itemButton:GetAttribute("Disabled") then
            self.button_connections["case_" .. tostring(itemButton.Name)] = itemButton.MouseButton1Click:Connect(function()
                self:OpenItemDisplay(itemButton:GetAttribute("Item"), itemButton:GetAttribute("ItemDisplayName"))
            end)
        end
    end

    -- [[ Connect Skin Buttons ]]
    self:CloseItemList()
    self.button_connections.skfback = self.Location.ItemListContainer_Skins.BackButton.MouseButton1Click:Connect(function()
        local curr, last = self.Location.ItemListContainer_Skins:GetAttribute("CurrentItemList"), self.Location.ItemListContainer_Skins:GetAttribute("LastItemList")
        if curr == last or curr == "MainList" then return end
        if last == "MainList" then
            self:CloseItemList()
        else
            self:OpenItemList(self.Location.ItemListContainer_Skins[last])
        end
        self.Location.ItemListContainer_Skins:SetAttribute("CurrentItemList", last)
    end)
end

function DisconnectButtons(self)
    for _, v in pairs(self.button_connections) do
        v:Disconnect()
    end
    self.button_connections = {}
end

-- [[ ITEM DISPLAY ]]
function Shop:OpenItemDisplay(item, itemDisplayName)
    if self.itemDisplayVar.active then return end
    self.itemDisplayVar.active = true -- turned off in CloseItemDisplay()

    local price = ShopInterface:GetItemPrice(item)
    local itemType = price.parsed.item_type

    self.itemDisplayFrame.Price_PC.Text = tostring(price.pc)
    self.itemDisplayFrame.Price_SC.Text = tostring(price.sc)

    if itemType == "case" then
        self.itemDisplayFrame.CaseDisplay.Visible = true
        self.itemDisplayFrame.ItemDisplayImageLabel.Visible = false
        self.itemDisplayFrame.ItemName.Text = string.upper(itemDisplayName) or string.upper(price.parsed.model)
    else
        self.itemDisplayFrame.CaseDisplay.Visible = false
        local imgLabel = self.itemDisplayFrame.ItemDisplayImageLabel
        imgLabel.Image = self:GetSkinDisplayImageID(price.parsed.model, price.parsed.skin) or imgLabel.Image
        self.itemDisplayFrame.ItemDisplayImageLabel.Visible = true
        self.itemDisplayFrame.ItemName.Text = tostring(price.parsed.skin)
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

    self.Location.ItemListContainer_Cases.Visible = false
    self.Location.ItemListContainer_Skins.Visible = false
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
    self.Location.ItemListContainer_Cases.Visible = true
    self.Location.ItemListContainer_Skins.Visible = true
    self.itemDisplayFrame.Visible = false
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
    if itemType == "case" then
        skinLabel.Visible = false
        weaponLabel.Visible = false
        caseLabel.Text = string.upper(tostring(price.parsed.model))
        caseLabel.Visible = true
    else
        skinLabel.Text = string.upper(tostring(price.parsed.skin))
        weaponLabel.Text = string.upper(tostring(price.parsed.model))
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
        Popup.burst("Successfully bought item! " .. tostring(parsedItem.model), 3)
        return true
    else
        Popup.burst("Could not buy item " .. tostring(parsedItem.model), 3)
        return false
    end
end

-- [[ ITEM LIST (CURRENTLY SKINS ONLY) ]]
function Shop:OpenItemList(frame, ignoreDisconnect)
    if self.itemListVar.OpenListName == frame.Name then
        return
    end
    self.Location.ItemListContainer_Skins:SetAttribute("LastItemList", self.itemListVar.OpenListName)
    self.Location.ItemListContainer_Skins:SetAttribute("CurrentItemList", frame.Name)
    self.itemListVar.OpenListName = frame.Name
    self.itemListFrame.Visible = false

    frame.Visible = true
    self.itemListFrame = frame
    self:_ConnectItemList(frame)
end

function Shop:CloseItemList() -- back to default, MainList
    if self.itemListVar.OpenListName ~= "MainList" then
        self.Location.ItemListContainer_Skins:SetAttribute("LastItemList", self.itemListVar.OpenListName)
        self.itemListFrame.Visible = false
        self.itemListVar.OpenListName = "MainList"
    end
    self.itemListFrame = self.itemListDefaultFrame
    self.itemListFrame.Visible = true
    self:_ConnectItemList(self.itemListFrame)
    self.Location.ItemListContainer_Skins:SetAttribute("CurrentItemList", "MainList")
end

function Shop:OpenLastItemList()
    local curr, last = self.Location.ItemListContainer_Skins:GetAttribute("CurrentItemList"), self.Location.ItemListContainer_Skins:GetAttribute("LastItemList")
    if curr == last or curr == "MainList" then return end
    if last == "MainList" then
        self:CloseItemList()
    else
        self:OpenItemList(self.Location.ItemListContainer_Skins[last])
    end
    self.Location.ItemListContainer_Skins:SetAttribute("CurrentItemList", last)
end

function Shop:_ConnectItemList(listFrame)
    local isMain = listFrame.Name == "MainList"

    if isMain then
        self.Location.ItemListContainer_Skins.BackButton.Visible = false
    else
        if self.itemListConns.Back then
            self.itemListConns.Back:Disconnect()
        end
        local backConnection = self.Location.ItemListContainer_Skins.BackButton.MouseButton1Click:Connect(function()
            self:OpenLastItemList()
        end)
        self.Location.ItemListContainer_Skins.BackButton.Visible = true
        self.itemListConns.Back = backConnection
    end

    self:_DelayDisconnectList(#self.itemListConns)
    
    for _, item in pairs(listFrame:GetChildren()) do
        if not item:IsA("Frame") then
            continue
        end

        local button = item:WaitForChild("TextButton")
        local connection = button.MouseButton1Click:Connect(function()
            if item.Parent.Name == "MainList" then
                local corrList = string.gsub(item.Name, "ButtonFrame_", "")
                corrList = item.Parent.Parent["ItemList_" .. corrList]
                self:OpenItemList(corrList, true)
            else
                local displayName = item:GetAttribute("ItemDisplayName") or string.upper(string.gsub(item.Name, "ItemList_", ""))
                self:OpenItemDisplay(item:GetAttribute("Item"), displayName)
            end
        end)

        table.insert(self.itemListConns, connection)
    end
end

function Shop:_DisconnectItemList()
    for _, v in pairs(self.itemListConns) do
        v:Disconnect()
    end
    self.itemListConns = {}
end

function Shop:_DelayDisconnectList(total)
    if total > 0 then
        task.delay(0.1, function()
            for i = 1, #self.itemListConns do
                self.itemListConns[i] = nil
            end
        end)
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
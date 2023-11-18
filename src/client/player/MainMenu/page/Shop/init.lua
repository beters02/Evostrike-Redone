local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup

local ShopInterface = require(Framework.Module.ShopInterface)
local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local AttemptShopPurchaseGui = ShopAssets:WaitForChild("AttemptItemPurchase")
local AttemptOpenCaseGui = ShopAssets:WaitForChild("AttemptOpenCase")

local Shop = {}

function Shop:init()
    self = setmetatable(Shop, self)
    self.Player = game.Players.LocalPlayer
    self.button_connections = {}

    self._sdframe = self.Location:WaitForChild("SkinDisplayFrame")
    self._sdvar = {}
    self._sdconns = {}

    self._cdframe = self.Location:WaitForChild("CaseDisplayFrame")
    self._cdvar = {}
    self._cdconns = {}

    self._ilconns = {}

    self.core_connections = {
        sc = PlayerData:PathValueChanged("economy.strafeCoins", function(new)
            self:Update(new)
        end),
        pc = PlayerData:PathValueChanged("economy.premiumCredits", function(new)
            self:Update(false, new)
        end)
    }

    local owned = self.Location:WaitForChild("OwnedFrame")
    self.pcLabel = owned:WaitForChild("PremiumCreditAmountLabel")
    self.scLabel = owned:WaitForChild("StrafeCoinAmountLabel")
    
    local sc, pc = self:GetEconomy()
    self:Update(sc, pc)
    return self
end

--

function Shop:Open()
    self:OpenAnimations()
    self:ConnectButtons()
end

function Shop:Close()
    self:CloseSkinDisplay()
    self:CloseItemList()
    self.Location.Visible = false
    self:DisconnectButtons()
end

function Shop:ConnectButtons()
    self:CloseItemList()
    self.button_connections.skfback = self.Location.SkinsFrame.BackButton.MouseButton1Click:Connect(function()
        local curr, last = self.Location.SkinsFrame:GetAttribute("CurrentItemList"), self.Location.SkinsFrame:GetAttribute("LastItemList")
        if curr == last or curr == "WeaponList" then return end
        if last == "WeaponList" then
            self:CloseItemList()
        else
            self:OpenItemList(string.gsub(last, "SkinList_"))
        end
        self.Location.SkinsFrame:SetAttribute("CurrentItemList", last)
    end)
end

function Shop:DisconnectButtons()
    for _, v in pairs(self.button_connections) do
        v:Disconnect()
    end
    self.button_connections = {}
end

function Shop:GetEconomy() --: sc, pc
    local pd = PlayerData:Get()
    return pd.economy.strafeCoins, pd.economy.premiumCredits
end

function Shop:Update(sc: number?, pc: number?)
    if sc then
        self.scLabel.Text = tostring(sc)
    end
    if pc then
        self.pcLabel.Text = tostring(pc)
    end
end

-- [[ ITEM LIST ]]
function Shop:OpenItemList(weapon)
    for _, v in pairs(self.Location.SkinsFrame) do
        if not v:IsA("Frame") then continue end
        if string.match(v.Name, weapon) then
            v.Visible = true
            self:ConnectItemList(v)
            self.Location.SkinFrame:SetAttribute("CurrentItemList", v.Name)
        else
            v.Visible = false
            self:DisconnectItemList(v)
        end
    end
end

function Shop:CloseItemList() -- back to default, WeaponList
    for _, v in pairs(self.Location.SkinsFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        if string.match(v.Name, "SkinList") then
            self:DisconnectItemList(v)
            if v.Visible then
                self.Location.SkinsFrame:SetAttribute("LastItemList", v.Name)
            end
        end
        v.Visible = false
    end
    self.Location.SkinsFrame.WeaponList.Visible = true
    self.Location.SkinsFrame:SetAttribute("CurrentItemList", "WeaponList")
    self:ConnectItemList(self.Location.SkinsFrame.WeaponList, "OpenCorrespondingList")
end

function Shop:ConnectItemList(frame, action: "OpenCorrespondingList" | "OpenSkinDisplay")
    self:DisconnectItemList(frame)
    self._ilconns[frame.Name] = {}
    for _, v in pairs(frame:GetChildren()) do
        if v:IsA("TextButton") then
            table.insert(self._ilconns, v.MouseButton1Click:Connect(function()
                if action == "OpenCorrespondingList" then
                    frame.Visible = false
                    frame.Parent[v.Name].Visible = true
                    self:ConnectItemList(frame.Parent[v.Name], "OpenSkinDisplay")
                    self.Location.SkinsFrame:SetAttribute("CurrentItemList", v.Name)
                    self.Location.SkinsFrame:SetAttribute("LastItemList", "WeaponList")
                elseif action == "OpenSkinDisplay" then
                    self:OpenSkinDisplay(frame:GetAttribute("weaponKey"), v:GetAttribute("skinKey"))
                end
                self:DisconnectItemList(frame)
            end))
        end
    end
end

function Shop:DisconnectItemList(frame)
    if self._ilconns[frame.Name] then
        for _, v in pairs(self._ilconns[frame.Name]) do
            v:Disconnect()
        end
        self._ilconns[frame.Name] = nil
    end
end

-- [[ SKIN DISPLAY ]]

function Shop:OpenSkinDisplay(weapon, skin)
    if self.Location:GetAttribute("SkinDisplayActive") then
        return
    end
    self.Location:SetAttribute("SkinDisplayActive", true)

    local item = "skin_" .. weapon .. "_" .. skin
    local price = ShopInterface:GetItemPrice(item)

    self._sdframe.ImageLabel.Image = self:GetSkinDisplayImageID(weapon, skin)
    self._sdframe.SkinName.Text = skin
    self._sdframe:WaitForChild("Price_SC").Text = tostring(price.sc)
    self._sdframe:WaitForChild("Price_PC").Text = tostring(price.pc)

    self.button_connections.SkinDisplayPurchase = self._sdframe:WaitForChild("PurchaseButton").MouseButton1Click:Connect(function()
        self:SkinDisplayPurchase(item, price, weapon, skin)
    end)

    self.button_connections.SkinDisplayBack = self._sdframe:WaitForChild("BackButton").MouseButton1Click:Connect(function()
        self:CloseSkinDisplay()
    end)

    self.Location.SkinsFrame.Visible = false
    self.Location.CasesFrame.Visible = false
    self.Location.SkinDisplayFrame.Visible = true
end

function Shop:CloseSkinDisplay()
    if not self.Location:GetAttribute("SkinDisplayActive") then
        return
    end
    self.Location:SetAttribute("SkinDisplayActive", false)

    for _, v in pairs(CollectionService:GetTagged("CloseSkinDisplay")) do
        v:Destroy()
    end
    self._sdvar.purchasing = false
    self:DisconnectSkinDisplay()

    self.Location.SkinDisplayFrame.Visible = false
    self.Location.SkinsFrame.Visible = true
    self.Location.CasesFrame.Visible = true
end

function Shop:DisconnectSkinDisplay()
    for _, v in pairs(self._sdconns) do
        v:Disconnect()
    end
end

function Shop:GetSkinDisplayImageID(weapon, skin): string
    return ReplicatedStorage:WaitForChild("Assets").Shop.SkinImages[skin][weapon].Image
end

function Shop:SkinDisplayPurchase(item, price, weapon, skin)
    if self._sdvar.purchasing then return end
    self._sdvar.purchasing = true
    --self:DisconnectSkinDisplay()

    local case = not skin and weapon or false
    price = price or ShopInterface:GetItemPrice(item)

    local close = case and function() self:CloseCaseDisplay() end or self:CloseSkinDisplay()

    local pgui = AttemptShopPurchaseGui:Clone()
    CollectionService:AddTag(pgui, case and "CloseCaseDisplay" or "CloseSkinDisplay")

    pgui:WaitForChild("Frame"):WaitForChild("PCAcceptButton").Text = tostring(price.pc) .. " PC"
    pgui:WaitForChild("Frame"):WaitForChild("SCAcceptButton").Text = tostring(price.sc) .. " SC"

    local boughtSuccessStr
    local boughtFailedStr
    if case then
        boughtSuccessStr = "Successfully bought key! " .. tostring(case)
        boughtFailedStr = "Could not buy key"
        pgui.Frame.SkinLabel.Visible = false
        pgui.Frame.WeaponLabel.Text = tostring(case)
    else
        boughtSuccessStr = "Successfully bought skin! " .. weapon .. " | " .. skin
        boughtFailedStr = "Could not buy skin"
        pgui.Frame.SkinLabel.Text = tostring(skin)
        pgui.Frame.WeaponLabel.Text = tostring(weapon)
    end
    
    pgui.Parent = self.Player.PlayerGui
    pgui.Enabled = true

    -- [[ CLICK: PURCHASE ]]
    self._sdconns[1] = pgui.Frame.SCAcceptButton.MouseButton1Click:Once(function()
        if ShopInterface:PurchaseItem(item, "StrafeCoins") then
            Popup.burst(boughtSuccessStr, 3)
        else
            Popup.burst(boughtFailedStr, 3)
        end

        pgui:Destroy()
        self._sdconns[3]:Disconnect()
        self._sdconns[2]:Disconnect()
        self._sdvar.purchasing = false
        close()
        self._sdconns[1]:Disconnect()
    end)

    self._sdconns[2] = pgui.Frame.PCAcceptButton.MouseButton1Click:Once(function()
        if ShopInterface:PurchaseItem(item, "PremiumCredits") then
            Popup.burst(boughtSuccessStr, 3)
        else
            Popup.burst(boughtFailedStr, 3)
        end

        pgui:Destroy()
        self._sdconns[3]:Disconnect()
        self._sdconns[1]:Disconnect()
        self._sdvar.purchasing = false
        self._sdconns[2]:Disconnect()
    end)

    self._sdconns[3] = pgui.Frame.DeclineButton.MouseButton1Click:Once(function()
        pgui:Destroy()
        self._sdconns[1]:Disconnect()
        self._sdconns[2]:Disconnect()
        self._sdvar.purchasing = false
        self._sdconns[3]:Disconnect()
    end)
end

-- [[ CASE DISPLAY ]]

function Shop:OpenCaseDisplay(case)
    if self.Location:GetAttribute("CaseDisplayActive") then
        return
    end
    self.Location:SetAttribute("CaseDisplayActive", true)

    local caseModel = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Cases"):FindFirstChild(case)
    assert(caseModel, "Case Model for " .. tostring(case) .. " non-existent.")

    self._cdframe.MainFrame.CaseNameLabel.Text = string.upper(tostring(case))
    local viewport = self._cdframe.MainFrame.CaseDisplay.ViewportFrame
    viewport:ClearAllChildren()
    caseModel:Clone().Parent = viewport

    local openingActive = false

    -- OPEN BUTTON
    self._cdconns.Open = self._cdframe.OpenButton.MouseButton1Click:Connect(function()
        if openingActive then return end
        openingActive = true

        local hasPurchased = false
        local pgui = AttemptOpenCaseGui:Clone()
        CollectionService:AddTag(pgui, "CloseCaseDisplay")

        local keyAcceptButton = pgui:WaitForChild("Frame"):WaitForChild("KeyAcceptButton")
        local hasKey = ShopInterface:HasKey(case)
        if hasKey then
            keyAcceptButton.Text = "use key"
            pgui.Frame.KeyNotOwnedLabel.Visible = false
        else
            pgui.Frame.KeyNotOwnedLabel.Visible = true
        end

        self._cdconns.Purchase = keyAcceptButton.MouseButton1Click:Connect(function()
            if hasPurchased then return end
            hasPurchased = true
            if hasKey then
                self:BeginCaseOpening(case)
            else
                self:SkinDisplayPurchase("key_weaponcase1")
            end
        end)
    end)

    self.Location.SkinsFrame.Visible = false
    self.Location.CasesFrame.Visible = false
    self._cdframe.Visible = true
end

function Shop:CloseCaseDisplay()
    if not self.Location:GetAttribute("CaseDisplayActive") then
        return
    end
    self.Location:SetAttribute("CaseDisplayActive", false)

    for _, v in pairs(CollectionService:GetTagged("CloseCaseDisplay")) do
        v:Destroy()
    end
    self._sdvar.purchasing = false
    self:DisconnectCaseDisplay()

    self.Location.CaseDisplayFrame.Visible = false
    self.Location.SkinsFrame.Visible = true
    self.Location.CasesFrame.Visible = true
end

function Shop:DisconnectCaseDisplay()
    for _, v in pairs(self._sdconns) do
        v:Disconnect()
    end
    for _, v in pairs(self._cdconns) do
        v:Disconnect()
    end
end

function Shop:BeginCaseOpening(case)
    
end

return Shop
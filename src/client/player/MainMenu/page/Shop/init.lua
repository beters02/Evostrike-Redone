local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local ShopInterface = require(Framework.Module.ShopInterface)
local AttemptShopPurchaseGui = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop"):WaitForChild("AttemptItemPurchase")
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup

local Shop = {}

function Shop:init()
    self = setmetatable(Shop, self)
    self.Player = game.Players.LocalPlayer
    self.button_connections = {}

    self._sdframe = self.Location:WaitForChild("SkinDisplayFrame")
    self._sdvar = {}
    self._sdconns = {}
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
        print('yuh')

        if self._sdvar.purchasing then return end
        self._sdvar.purchasing = true
        --self:DisconnectSkinDisplay()

        local pgui = AttemptShopPurchaseGui:Clone()
        CollectionService:AddTag(pgui, "CloseSkinDisplay")

        pgui:WaitForChild("Frame"):WaitForChild("PCAcceptButton").Text = tostring(price.pc) .. " PC"
        pgui:WaitForChild("Frame"):WaitForChild("SCAcceptButton").Text = tostring(price.sc) .. " SC"
        pgui.Frame.SkinLabel.Text = tostring(skin)
        pgui.Frame.WeaponLabel.Text = tostring(weapon)
        pgui.Parent = self.Player.PlayerGui
        pgui.Enabled = true

        -- [[ CLICK: PURCHASE ]]
        self._sdconns[1] = pgui.Frame.SCAcceptButton.MouseButton1Click:Once(function()
            if ShopInterface:PurchaseItem(item, "StrafeCoins") then
                Popup.burst("Successfully bought skin! " .. weapon .. " | " .. skin, 3)
            else
                Popup.burst("Could not buy skin.", 3)
            end

            pgui:Destroy()
            self._sdconns[3]:Disconnect()
            self._sdconns[2]:Disconnect()
            self._sdvar.purchasing = false
            self:CloseSkinDisplay()
            self._sdconns[1]:Disconnect()
        end)

        self._sdconns[2] = pgui.Frame.PCAcceptButton.MouseButton1Click:Once(function()
            if ShopInterface:PurchaseItem(item, "PremiumCredits") then
                Popup.burst("Successfully bought skin! " .. weapon .. " | " .. skin, 3)
            else
                Popup.burst("Could not buy skin.", 3)
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

return Shop
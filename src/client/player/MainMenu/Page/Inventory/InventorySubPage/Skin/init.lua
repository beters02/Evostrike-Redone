-- [[ Skin Inventory SubPage Module]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local InventoryInterface2 = require(Framework.Module.InventoryInterface)
local Strings = require(Framework.shfc_strings.Location)
local ShopRarity = require(ReplicatedStorage.Assets.Shop.Rarity)
local ShopInterface = require(Framework.Module.ShopInterface)
local PlayerData = require(Framework.Module.PlayerData)
local Popup = require(script.Parent.Parent.Parent.Parent.Popup)

local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local AttemptItemSellGui = ShopAssets:WaitForChild("AttemptItemSell")

local InventorySubPage = require(script.Parent)
local Frames = require(script:WaitForChild("Frames"))
local Organize = require(script:WaitForChild("Organize"))
local Config = require(script:WaitForChild("Config"))
local Skin = setmetatable({}, InventorySubPage)
Skin.__index = Skin

-- Base Functions

function Skin:init(Inventory, Frame)
    Skin = setmetatable(InventorySubPage.new(Inventory, Frame, "Skin"), Skin)
    Skin.Var = {Equipping = false, IsSelling = false}
    Skin.SkinFrameConnections = {}

    Skin.ItemDisplay.Frame.MainButton.Text = "EQUIP"
    Skin.ItemDisplay.Frame.SecondaryButton.Text = "SELL"

    Skin.SkinPageFrames = {}
    Skin.EquippedSkinPageFrames = {}
    for i, _ in pairs(PlayerData:Get().ownedItems.equipped) do
        Skin.EquippedSkinPageFrames[i] = false
    end

    Skin.ItemDisplay.ClickedMainButton = function(itd)
        Skin.Inventory.Main:PlayButtonSound("Select1")
        if Skin:SetSkinEquipped() then
            itd.Frame.MainButton.Text = "EQUIPPED"
        end
    end

    Skin.ItemDisplay.ClickedSecondaryButton = function(itd)
        Skin.Inventory.Main:PlayButtonSound("Select1")
        Skin:SellSkin(Skin.CurrentOpenSkinFrame)
    end

    Skin.ItemDisplay.ClickedBackButton = function(itd)
        Skin.Inventory.Main:PlayButtonSound("Select1")
        Skin.Frame.Visible = true
        Skin:CloseItemDisplay()
        Skin.Inventory:EnableSubPageButtons()
    end

    Skin.ItemDisplay.ChangeDisplayedItem = changeDisplayItem
    return Skin
end

function Skin:Open()
    InventorySubPage.Open(self)
    Frames.ConnectSkinFrames(self)
    self.Connections.DropdownPrimary = self.Frame.SortByDropdown.Button.MouseButton1Click:Connect(function()
        MainOrganizeButtonClicked(self)
    end)
end

function Skin:Close()
    InventorySubPage.Close(self)
    Frames.DisconnectSkinFrames(self)
end

function Skin:Update()
    InventorySubPage.Update(self)
    Frames.UpdateSkinFrames(self)
end

--@summary Set specific skin frame or CurrentSkinFrame equipped
function Skin:SetSkinEquipped(skinFrame: Frame?)
    if self.Var.Equipping then return false end
    self.Var.Equipping = true

    local skinfo = self.ItemDisplay.Var.CurrentSkinfo

    if skinFrame then
        skinfo = Frames.GetSkinFromFrame(skinFrame)
        skinfo.frame = skinFrame
    end

    local succ, err = pcall(function()
        InventoryInterface2.SetEquippedSkinFromSkinObject(skinfo)
    end)

    if not succ then
        warn(err)
        self.Var.Equipping = false
        return false
    end

    Frames.SetSkinFrameEquipped(self, skinfo)
    self.Var.Equipping = false
    return true
end

function Skin:SellSkin(frame)
    local invSkin = Frames.GetSkinFromFrame(frame)

    if not canSellItem(invSkin) then return end
    if self.Var.IsSelling then return end
    self.Var.IsSelling = true

    local isEquipped = frame:GetAttribute("Equipped")

    local shopItemStr = "skin_"
    if invSkin.weapon == "knife" then
        shopItemStr = shopItemStr .. "knife_"
    end
    shopItemStr = shopItemStr .. invSkin.model .. "_" .. invSkin.skin
    local shopItem = ShopInterface:GetItemPrice(shopItemStr)

    local confirmgui = AttemptItemSellGui:Clone()
    local mainframe = confirmgui:WaitForChild("Frame")
    confirmgui.Parent = game.Players.LocalPlayer.PlayerGui

    mainframe:WaitForChild("CaseLabel").Visible = false
    mainframe:WaitForChild("WeaponLabel").Visible = true
    mainframe:WaitForChild("SkinLabel").Visible = true

    mainframe.WeaponLabel.Text = Strings.firstToUpper(invSkin.model)
    mainframe.SkinLabel.Text = Strings.firstToUpper(invSkin.skin)
    mainframe.SCAcceptButton.Text = tostring(shopItem.sell_sc) .. " SC"

    local conns = {}
    conns[1] = mainframe.SCAcceptButton.MouseButton1Click:Once(function()
        conns[2]:Disconnect()
        local succ = ShopInterface:SellItem(shopItemStr, invSkin.unsplit)
        if succ then
            self.Inventory.Main:PlayButtonSound("Purchase1")
            Popup.new(game.Players.LocalPlayer, "Successfully sold item for " .. tostring(shopItem.sell_sc) .. " SC!", 3)
            confirmgui:Destroy()
            self:CloseItemDisplay()
            self.Frame.Visible = true

            if isEquipped then
                InventoryInterface2.SetEquippedAsDefault(invSkin.weapon)
                local defFr = Frames.GetDefaultWeaponSkinFrame(self, invSkin.weapon)
                local defSkinfo = Frames.GetSkinFromFrame(defFr)
                defSkinfo.frame = defFr
                Frames.SetSkinFrameEquipped(self, defSkinfo)
            end

            Frames.UpdateSkinFrames(self)
            Frames.ConnectSkinFrames(self)
            self.Var.IsSelling = false
            conns[1]:Disconnect()
            return
        end

        self.Inventory.Main:PlayButtonSound("Error1")
        Popup.new(game.Players.LocalPlayer, "Could not sell item.", 3)
        self.Var.IsSelling = false
        confirmgui:Destroy()
        conns[1]:Disconnect()
    end)

    conns[2] = mainframe.DeclineButton.MouseButton1Click:Once(function()
        conns[1]:Disconnect()
        confirmgui:Destroy()
        self.Var.IsSelling = false
        conns[2]:Disconnect()
    end)

    confirmgui.Enabled = true
end

function getSkinFromName(weapon, model, skin, uuid)
    model = model or weapon
    uuid = uuid or 0
    return InventoryInterface2.ParseSkinString(weapon .. "_" .. model .. "_" .. skin .. "_" .. uuid)
end

function changeDisplayItem(itd, skinfo)
    itd.Frame.ItemName.Text = Strings.firstToUpper(skinfo.model) .. " | " .. Strings.firstToUpper(skinfo.skin)
    itd.Frame.IDLabel.Visible = true
    itd.Frame.IDLabel.Text = "ID: " .. tostring(skinfo.uuid)

    local rarity = skinfo.rarity
    local rarityColor = rarity and ShopRarity[rarity].color
    rarity = rarity or "Default"
    itd.Frame.RarityLabel.Visible = true
    itd.Frame.RarityLabel.Text = rarity
    if rarityColor then
        itd.Frame.RarityLabel.TextColor3 = rarityColor
    end
    
    itd.Frame.ItemDisplayImageLabel.Visible = false
    itd.Frame.CaseDisplay.Visible = true
    itd.Frame.CaseDisplay.ViewportFrame:ClearAllChildren()

    local model = Frames.CreateSkinFrameModel(skinfo)
    model.Parent = itd.Frame.CaseDisplay.ViewportFrame
    model:SetPrimaryPartCFrame(model.PrimaryPart.CFrame + Vector3.new(0,0,7.8))

    itd.Var.CurrentSkinfo = skinfo
    print(skinfo)
end

function canSellItem(invskin)
    return invskin.uuid ~= 0
end

--

local isDropdownEnabled = false
local currentOrganizeSelected = "Date Added"

function MainOrganizeButtonClicked(self)
    OrganizeButtonClicked(self, currentOrganizeSelected)
end

function OrganizeButtonClicked(self, typeSelected)
    if not isDropdownEnabled then
        isDropdownEnabled = true
        OpenDropdown(self)
    else
        isDropdownEnabled = false
        currentOrganizeSelected = typeSelected
        self.Frame.SortByDropdown.Button.Text = "SORT BY: " .. string.upper(typeSelected)
        Organize["By"..string.gsub(typeSelected, "%s+", "")](self, "Descending")
        CloseDropdown(self)
    end
end

function OpenDropdown(self)
    local ddFrame: Frame = self.Frame.SortByDropdown
    local mainButton: TextButton = ddFrame.Button

    for _, v in pairs(Config.OrganizeOptions) do
        if v == currentOrganizeSelected then
            continue
        end

        local secButton: TextButton? = ddFrame:FindFirstChild(v)
        if not secButton then
            secButton = Instance.new("TextButton", self.Frame.SortByDropdown)
            secButton.Text = string.upper(v)
            secButton.BackgroundColor3 = mainButton.BackgroundColor3
            secButton.BackgroundTransparency = mainButton.BackgroundTransparency
            secButton.Size = mainButton.Size
            secButton.TextColor3 = mainButton.TextColor3
            for _, b in pairs(mainButton:GetChildren()) do
                b:Clone().Parent = secButton
            end
            secButton.FontFace = mainButton.FontFace

            local pos = mainButton.Position
            secButton.Position = UDim2.new(
                pos.X.Scale,
                pos.X.Offset,
                pos.Y.Scale + mainButton.Size.Y.Scale + 0.02,
                pos.Y.Offset
            )
        end

        self.Connections["DropdownSecondary"..v] = secButton.MouseButton1Click:Connect(function()
            OrganizeButtonClicked(self, v)
        end)
    end
end

function CloseDropdown(self)
    for i, v in pairs(self.Frame.SortByDropdown:GetChildren()) do
        if v:IsA("TextButton") and v.Name ~= "Button" then
            v:Destroy()
        end
    end
    for i, v in pairs(self.Connections) do
        if string.match(i, "DropdownSecondary") then
            v:Disconnect()
            self.Connections[i] = nil
        end
    end
end

return Skin
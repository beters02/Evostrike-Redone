local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.shfc_strings.Location)
local InventoryInterface2 = require(Framework.Module.InventoryInterface)
local ShopInterface = require(Framework.Module.ShopInterface)
local WeaponService = ReplicatedStorage:WaitForChild("Services"):WaitForChild("WeaponService")
local WeaponModules = WeaponService:WaitForChild("Weapon")
local PlayerData = require(Framework.Module.PlayerData)
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local ShopSkins = require(ReplicatedStorage.Assets.Shop.Skins)
local ShopRarity = require(ReplicatedStorage.Assets.Shop.Rarity)

local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local AttemptItemSellGui = ShopAssets:WaitForChild("AttemptItemSell")

local SkinPage = {
    config = {
        MaxFramesPerPage = 21
    }
}

SkinPage.CustomWeaponPositions = {
    Get = function(invSkin)
        if invSkin.weapon == "knife" then
            par = SkinPage.CustomWeaponPositions.knife[invSkin.model]
        else
            par = SkinPage.CustomWeaponPositions[invSkin.model]
        end
        return par and par[invSkin.skin]
    end,

    knife = {
        wepcf = CFrame.new(Vector3.new(1, 0, -3)),
        karambit = {wepcf = CFrame.new(Vector3.new(-0.026, -0.189, -1.399))},
        default = {wepcf = CFrame.new(Vector3.new(0.143, -0.5, -2.1)), wepor = Vector3.new(0, 180, 180)},
        m9bayonet = {wepcf = CFrame.new(Vector3.new(-0.029, -0, -1.674))},
    },
    ak103 = {wepor = Vector3.new(90, 170, 0)},
    glock17 = {wepcf = CFrame.new(Vector3.new(-0.4, 0.2, -1.4)), wepor = Vector3.new(0, 90, -180)},
    deagle = {wepcf = CFrame.new(Vector3.new(-0.1, 0, -1.5)), wepor = Vector3.new(0, -180, -180)}
}

function SkinPage:init(frame)
    self.SkinPageFrames = {}
    self.EquippedSkinPageFrames = {}
    self.SkinPageNumberVar = {
        Connections = {},
        PageAmount = 1,
        CurrentPage = 1,
    }
    for i, _ in pairs(PlayerData:Get().ownedItems.equipped) do
        self.EquippedSkinPageFrames[i] = false
    end
    SkinPage.MainFrame = frame
end

function SkinPage:Open()
    self.Location.Case.Visible = false
    self.Location.Key.Visible = false
    self.Location.Skin.Visible = true
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    SkinPage.ConnectButtons(self)
end

function SkinPage:Clear()
    for _, page in pairs(self.SkinPageFrames) do
        for _, obj in pairs(page) do
            obj[2]:Destroy()
        end
    end
    for _, content in pairs(self.Location.Skin:GetChildren()) do
        if content:IsA("Frame") and content.Name ~= "Content1" then
            content:Destroy()
        end
    end
    self.Location.Skin.Content1.Visible = true
    self.SkinPageFrames = {}
end

function SkinPage:Update(playerInventory)
    SkinPage.DisconnectButtons(self)
    SkinPage.Clear(self)

    local frames = {[1] = {}} -- index per page number (pagesAmount)
    local skinsToCreate = {}
    local pagesAmount = 1
    local pageIndex = 1

    -- first we get all the skins in an array so we can count
    if self._isPlayerAdmin then
        skinsToCreate = SkinPage.GetAllSkins(self)
    else
        skinsToCreate = SkinPage.GetAllDefaultSkins(self)
    end
    for _, unsplit in pairs(playerInventory.skin) do
        table.insert(skinsToCreate, unsplit)
    end

    -- count for number of pages
    pagesAmount = math.ceil(#skinsToCreate/SkinPage.config.MaxFramesPerPage)
    self.SkinPageNumberVar.PageAmount = pagesAmount
    if pagesAmount > 1 then
        SkinPage.ConnectPageNumberButtons(self)
        for i = 2, pagesAmount+1 do
            local c = self.Location.Skin.Content1:Clone()
            c.Name = "Content" .. tostring(i)
            c.Parent = self.Location.Skin
            c.BackgroundTransparency = 0.944
            c.Visible = false
            frames[i] = {}
        end
    end

    -- add equipped skins
    for _, unsplit in pairs(playerInventory.equipped) do
        if #frames[pageIndex] >= SkinPage.config.MaxFramesPerPage then
            pageIndex += 1
        end

        local invSkin = InventoryInterface2.ParseSkinString(unsplit)
        local frame = SkinPage.CreateSkinFrame(self, unsplit, pageIndex)
        for i, v in pairs(invSkin) do
            frame:SetAttribute(i, v)
        end
        SkinPage.SetSkinFrameEquipped(self, frame, invSkin, true)
        table.insert(frames[pageIndex], {unsplit, frame})
    end

    -- add all other skins
    for _, unsplit in pairs(skinsToCreate) do
        if table.find(playerInventory.equipped, unsplit) then
            continue
        end
        if #frames[pageIndex] >= SkinPage.config.MaxFramesPerPage then
            pageIndex += 1
        end

        local invSkin = InventoryInterface2.ParseSkinString(unsplit)
        local frame = SkinPage.CreateSkinFrame(self, unsplit, pageIndex)
        for i, v in pairs(invSkin) do
            frame:SetAttribute(i, v)
        end
        table.insert(frames[pageIndex], {unsplit, frame})
    end

    self.SkinPageFrames = frames
    SkinPage.ConnectButtons(self)
end

function SkinPage:ConnectButtons()
    for _, content in pairs(self.Location.Skin:GetChildren()) do
        if content:IsA("Frame") and string.match(content.Name, "Content") then
            for _, v in pairs(content:GetChildren()) do
                if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
                table.insert(self.currentPageButtonConnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
                    if not self.Location.Skin.Visible or not v.Parent.Visible then return end
                    SkinPage.SkinFrameButtonClicked(self, v)
                end))
            end
        end
    end
end

function SkinPage:DisconnectButtons()
    for _, v in pairs(self.currentPageButtonConnections) do
        v:Disconnect()
    end
    self.currentPageButtonConnections = {}
    SkinPage.DisconnectPageNumberButtons(self)
end

function SkinPage:ConnectPageNumberButtons()
    if self.SkinPageNumberVar.Connections.NextPageNum then
        self.SkinPageNumberVar.Connections.NextPageNum:Disconnect()
    end
    if self.SkinPageNumberVar.Connections.PrevPageNum then
        self.SkinPageNumberVar.Connections.PrevPageNum:Disconnect()
    end

    self.SkinPageNumberVar.Connections.NextPageNum = self.Location.NextPageNumberButton.MouseButton1Click:Connect(function()
        local curr = self.SkinPageNumberVar.CurrentPage
        if curr == self.SkinPageNumberVar.PageAmount then
            return
        end
        self.Location.Skin["Content" .. tostring(curr)].Visible = false

        curr += 1
        self.Location.Skin["Content" .. tostring(curr)].Visible = true
        self.Location.CurrentPageNumberLabel.Text = tostring(curr)
        self.SkinPageNumberVar.CurrentPage = curr
    end)

    self.SkinPageNumberVar.Connections.PrevPageNum = self.Location.PreviousPageNumberButton.MouseButton1Click:Connect(function()
        local curr = self.SkinPageNumberVar.CurrentPage
        if curr == 1 then
            return
        end
        self.Location.Skin["Content" .. tostring(curr)].Visible = false

        curr -= 1
        self.Location.Skin["Content" .. tostring(curr)].Visible = true
        self.Location.CurrentPageNumberLabel.Text = tostring(curr)
        self.SkinPageNumberVar.CurrentPage = curr
    end)
end

function SkinPage:DisconnectPageNumberButtons()
    for _, v in pairs(self.SkinPageNumberVar.Connections) do
        v:Disconnect()
    end
    self.SkinPageNumberVar.Connections = {}
end

function SkinPage:CreateSkinFrame(skinStr, pageIndex)
    local invSkin = InventoryInterface2.ParseSkinString(skinStr):: InventoryInterface2.InventorySkinObject
    local displayName = Strings.firstToUpper(invSkin.model) .. " | " .. Strings.firstToUpper(invSkin.skin)

    local frame = self.Location.Skin.Content1.ItemFrame:Clone()
    frame:WaitForChild("NameLabel").Text = displayName
    frame.Name = "SkinFrame_" .. displayName
    frame.Parent = self.Location.Skin["Content" .. tostring(pageIndex)]
    frame.BackgroundColor3 = frame:GetAttribute("unequippedColor")

    if (invSkin.weapon == "knife" and invSkin.model ~= "default") or (invSkin.weapon ~= "knife" and invSkin.skin ~= "default") then
        frame:SetAttribute("rarity", ShopSkins.GetSkinFromInvString(skinStr).rarity)
    end

    frame:SetAttribute("weapon", invSkin.weapon)
    frame:SetAttribute("model", invSkin.model)
    frame:SetAttribute("skin", invSkin.skin)
    frame:SetAttribute("uuid", invSkin.uuid)
    frame:SetAttribute("Equipped", false)

    local weaponModel = SkinPage.CreateSkinFrameModel(self, invSkin)
    weaponModel.Parent = frame:WaitForChild("ViewportFrame")
    frame.Visible = true
    return frame
end

function SkinPage:CreateSkinFrameModel(invSkin: InventoryInterface2.InventorySkinObject)
    local weaponModelObj = InventoryInterface2.GetSkinModelFromSkinObject(invSkin):Clone()
    if weaponModelObj:FindFirstChild("Server") then -- Prioritize Server Model in Inventory.
        local server = weaponModelObj.Server
        server.Parent = weaponModelObj.Parent
        weaponModelObj:Destroy()
        weaponModelObj = server
    end
    weaponModelObj.PrimaryPart = weaponModelObj.GunComponents.WeaponHandle

    -- get custom weapon positions
    local wepcf = CFrame.new(Vector3.new(1,0,-4))
    wepcf = SkinPage.CustomWeaponPositions.Get(invSkin) or wepcf

    local wepor = Vector3.new(90, 0, 0)
    wepor = SkinPage.CustomWeaponPositions.Get(invSkin) or wepor

    weaponModelObj:SetPrimaryPartCFrame(wepcf)
    weaponModelObj.PrimaryPart.Orientation = wepor
    return weaponModelObj
end

function SkinPage:SkinFrameButtonClicked(skinFrame)
    local invSkin = SkinPage.GetSkinFromFrame(self, skinFrame)
    SkinPage.OpenItemDisplay(self, invSkin, skinFrame)
end

local function weld(model, doWeld)
    for _, v in pairs(model.GunComponents.WeaponHandle:GetChildren()) do
        if v:IsA("Weld") then
            v.Enabled = doWeld or false
        end
    end
end

function SkinPage:OpenItemDisplay(invSkin: InventoryInterface2.InventorySkinObject, skinFrame)
    if self.itemDisplayVar.active then return end
    self.itemDisplayVar.active = true -- turned off in CloseItemDisplay()

    self.itemDisplayFrame.ItemName.Text = Strings.firstToUpper(invSkin.model) .. " | " .. Strings.firstToUpper(invSkin.skin)
    self.itemDisplayFrame.IDLabel.Visible = true
    self.itemDisplayFrame.IDLabel.Text = "ID: " .. tostring(invSkin.uuid)

    local rarity = skinFrame:GetAttribute("rarity")
    local rarityColor = rarity and ShopRarity[rarity].color
    rarity = rarity or "Default"

    self.itemDisplayFrame.RarityLabel.Visible = true
    self.itemDisplayFrame.RarityLabel.Text = rarity
    if rarityColor then
        self.itemDisplayFrame.RarityLabel.TextColor3 = rarityColor
    end
    
    -- Model Display
    self.itemDisplayFrame.ItemDisplayImageLabel.Visible = false
    self.itemDisplayFrame.CaseDisplay.Visible = true
    self.itemDisplayFrame.CaseDisplay.ViewportFrame:ClearAllChildren()
    local model = InventoryInterface2.GetSkinModelFromSkinObject(invSkin):Clone()
    local clientModel = false
    if model:FindFirstChild("Server") then
        clientModel = model
        model = model.Server
    end
    model = model::Model
    model.Parent = self.itemDisplayFrame.CaseDisplay.ViewportFrame
    model.PrimaryPart = model:WaitForChild("GunComponents"):WaitForChild("WeaponHandle")

    weld(model, false)
    model.PrimaryPart.CFrame = CFrame.new(model.PrimaryPart.CFrame.Position, Vector3.zero)
    weld(model, true)

    model:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0,0,0)) * CFrame.Angles(90,0,0))
    if clientModel then
        clientModel:Destroy()
    end

    -- Init Equip Button
    self.itemDisplayFrame.MainButton.Text = "EQUIP"
    local isEquipped = false
    local equippedInvSkin = InventoryInterface2.GetEquippedSkin(invSkin.weapon)
    if equippedInvSkin and equippedInvSkin.weapon == invSkin.weapon and equippedInvSkin.model == invSkin.model and equippedInvSkin.skin == invSkin.skin and equippedInvSkin.uuid == invSkin.uuid then
        isEquipped = true
        self.itemDisplayFrame.MainButton.Text = "EQUIPPED"
    end

    -- Init Sell Button
    self.itemDisplayFrame.SecondaryButton.Text = "SELL"
    self.itemDisplayFrame.SecondaryButton.Visible = true
    local canSell = true
    if tonumber(invSkin.uuid) == 0 then
        print("Cant sell because 0 uuid")
        canSell = false
        self.itemDisplayFrame.SecondaryButton.Visible = false
    end

    -- "Equip"
    self.itemDisplayConns.MainButton = self.itemDisplayFrame.MainButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.isEquipping or isEquipped then
            return
        end
        self.itemDisplayVar.isEquipping = true

        local succ, err = pcall(function()
            InventoryInterface2.SetEquippedSkinFromSkinObject(invSkin)
            SkinPage.SetSkinFrameEquipped(self, skinFrame, invSkin)
            isEquipped = true
            self.itemDisplayFrame.MainButton.Text = "EQUIPPED"
        end)
        if not succ then
            warn(err)
        end

        self.itemDisplayVar.isEquipping = false
    end)

    -- "Sell"
    self.itemDisplayConns.SecondaryButton = self.itemDisplayFrame.SecondaryButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.isSelling or not canSell then
            return
        end
        self.itemDisplayVar.isSelling = true

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
                self:PlaySound("Purchase1")
                Popup.burst("Successfully sold item for " .. tostring(shopItem.sell_sc) .. " SC!", 3)
                SkinPage.CloseItemDisplay(self)
                SkinPage.ConnectButtons(self)
                if isEquipped then
                    local defStr = InventoryInterface2.SetEquippedAsDefault(invSkin.weapon)
                    local defFrame = SkinPage.GetSkinFrame(self, invSkin.weapon, "default", 0)
                    SkinPage.SetSkinFrameEquipped(self, defFrame, InventoryInterface2.ParseSkinString(defStr), true)
                end
            else
                self:PlaySound("Error1")
                Popup.burst("Could not sell item.", 3)
            end
            self.itemDisplayVar.isSelling = false
            confirmgui:Destroy()
            conns[1]:Disconnect()
        end)

        conns[2] = mainframe.DeclineButton.MouseButton1Click:Once(function()
            conns[1]:Disconnect()
            confirmgui:Destroy()
            self.itemDisplayVar.isSelling = false
            conns[2]:Disconnect()
        end)

        confirmgui.Enabled = true
    end)

    self.itemDisplayConns.BackButton = self.itemDisplayFrame.BackButton.MouseButton1Click:Connect(function()
        SkinPage.CloseItemDisplay(self)
        self.itemDisplayVar.isSelling = false
    end)

    self.LastOpenPage = self.Location.Case.Visible and self.Location.Case or self.Location.Skin
    self.Location.Case.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.Visible = false
    self.Location.SkinsButton.Visible = false
    self.Location.KeysButton.Visible = false
    self.Location.NextPageNumberButton.Visible = false
    self.Location.PreviousPageNumberButton.Visible = false
    self.Location.CurrentPageNumberLabel.Visible = false
    self.itemDisplayFrame.Visible = true
    self:PlaySound("ItemDisplay")
end

type skinObject = InventoryInterface2.InventorySkinObject
function SkinPage:OpenItemDisplayNew(invSkin: skinObject, skinFrame)
    self.ItemDisplay.Open(
        self,
        {
            ItemName = Strings.firstToUpper(invSkin.model) .. " | " .. Strings.firstToUpper(invSkin.skin),
            Rarity = skinFrame:GetAttribute("rarity") or "Default",
            UUID = tostring(invSkin.uuid)
        },
        function(ItemDisplay)

        end)
end

function SkinPage:CloseItemDisplay()
    self.itemDisplayVar.active = false
    for _, v in pairs(self.itemDisplayConns) do
        v:Disconnect()
    end
    self.itemDisplayFrame.Visible = false
    if self.LastOpenPage then
        self.LastOpenPage.Visible = true
    end
    self.Location.CasesButton.Visible = true
    self.Location.SkinsButton.Visible = true
    self.Location.KeysButton.Visible = true
    self.Location.NextPageNumberButton.Visible = true
    self.Location.PreviousPageNumberButton.Visible = true
    self.Location.CurrentPageNumberLabel.Visible = true
end

function SkinPage:SetSkinFrameEquipped(frame, skin: InventoryInterface2.InventorySkinObject, ignoreUnequip: boolean)
    frame.BackgroundColor3 = frame:GetAttribute("equippedColor")
    frame:SetAttribute("Equipped", true)

    if not ignoreUnequip then
        local currEquippedFrame = self.EquippedSkinPageFrames[skin.weapon]

        if currEquippedFrame then
            currEquippedFrame.BackgroundColor3 = currEquippedFrame:GetAttribute("unequippedColor")
            currEquippedFrame:SetAttribute("Equipped", false)
        end
    end

    self.EquippedSkinPageFrames[skin.weapon] = frame
end

-- [[ UTIL ]]
function SkinPage:ParseSkinString(str)
    local _sep = str:split("_")
    return {weapon = _sep[1], model = _sep[2], knifeSkin = _sep[3]}
end

function SkinPage:GetSkinFrame(weapon: string, skin: string, uuid)
    for _, content in pairs(self.Location.Skin:GetChildren()) do
        if content:IsA("Frame") and string.match(content.Name, "Content") then
            for _, v in pairs(content:GetChildren()) do
                if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
                if v:GetAttribute("weapon") == weapon and v:GetAttribute("skin") == skin and tostring(v:GetAttribute("uuid")) == tostring(uuid) then
                    return v
                end
            end
        end
    end
    return false
end

function SkinPage:GetSkinFromFrame(frame)
    local str = ""
    local tab = {"weapon", "model", "skin", "uuid"}
    for i, v in pairs(tab) do
        str = str .. frame:GetAttribute(v)
        if i ~= #tab then
            str = str .. "_"
        end
    end
    return InventoryInterface2.ParseSkinString(str)
end

function SkinPage:_getDefaultSkins(equippedInventory)
    local defaults = {}
    for i, _ in pairs(equippedInventory) do
        if i == "knife" then
            defaults[i] = "knife_default_default_0"
        else
            defaults[i] = i .. "_" .. i .. "_" .. "default_0"
        end
    end
    return defaults
end

-- [[ UNNECCESSARY BUT HERE IT IS UTIL ]]
function SkinPage:CreateSkinFramesForAllWeapons(frames) -- Sets UUIDs as 0 for all.
    frames = frames or {}
    for _, weaponFolder in pairs(WeaponModules:GetChildren()) do
        local weaponName = weaponFolder.Name

        if weaponName == "knife" then
            for _, model in pairs(weaponFolder.Assets:GetChildren()) do
                for _, skin in pairs(model.Models:GetChildren()) do
                    if not skin:IsA("Model") or skin:GetAttribute("Ignore") then
                        continue
                    end
                    local id = "knife_" .. model.Name .. "_" .. skin.Name .. "_0"
                    frames[id] = SkinPage.CreateSkinFrame(self, id)
                end
            end
        else
            for _, skin in pairs(weaponFolder.Assets.Models:GetChildren()) do
                if not skin:IsA("Model") or skin:GetAttribute("Ignore") then
                    continue
                end
                local id = weaponName .. "_" .. weaponName .. "_" .. skin.Name .. "_0"
                frames[id] = SkinPage.CreateSkinFrame(self, id)
            end
        end
    end
end

function SkinPage:CreateSkinFramesForAllDefaultWeapons(frames)
    for _, weaponFolder in pairs(WeaponModules:GetChildren()) do
        if not weaponFolder:FindFirstChild("Assets") then
            continue
        end

        local weaponName = weaponFolder.Name
        local inventoryKey = weaponName .. "_" .. weaponName .. "_default_0"

        if weaponName == "knife" then
            inventoryKey = "knife_default_default_0"
        end

        frames[inventoryKey] = SkinPage.CreateSkinFrame(self, inventoryKey)
    end
end

function SkinPage:GetAllSkins()
    local skins = {}
    for _, weaponFolder in pairs(WeaponModules:GetChildren()) do
        local weaponName = weaponFolder.Name

        if weaponName == "knife" then
            for _, model in pairs(weaponFolder.Assets:GetChildren()) do
                for _, skin in pairs(model.Models:GetChildren()) do
                    if not skin:IsA("Model") or skin:GetAttribute("Ignore") then
                        continue
                    end
                    local id = "knife_" .. model.Name .. "_" .. skin.Name .. "_0"
                    table.insert(skins, id)
                end
            end
        else
            for _, skin in pairs(weaponFolder.Assets.Models:GetChildren()) do
                if not skin:IsA("Model") or skin:GetAttribute("Ignore") then
                    continue
                end
                local id = weaponName .. "_" .. weaponName .. "_" .. skin.Name .. "_0"
                table.insert(skins, id)
            end
        end
    end
    return skins
end

function SkinPage:GetAllDefaultSkins()
    local skins = {}
    for _, weaponFolder in pairs(WeaponModules:GetChildren()) do
        if not weaponFolder:FindFirstChild("Assets") then
            continue
        end

        local weaponName = weaponFolder.Name
        local inventoryKey = weaponName .. "_" .. weaponName .. "_default_0"

        if weaponName == "knife" then
            inventoryKey = "knife_default_default_0"
        end

        table.insert(skins, inventoryKey)
    end
    return skins
end

return SkinPage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.shfc_strings.Location)
local InventoryInterface2 = require(Framework.Module.InventoryInterface)
local ShopInterface = require(Framework.Module.ShopInterface)
local WeaponService = ReplicatedStorage:WaitForChild("Services"):WaitForChild("WeaponService")
local WeaponModules = WeaponService:WaitForChild("Weapon")
local PlayerData = require(Framework.Module.PlayerData)
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup

local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local AttemptItemSellGui = ShopAssets:WaitForChild("AttemptItemSell")

local SkinPage = {}

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
    for _, v in pairs(self.SkinPageFrames) do
        v:Destroy()
    end
    self.SkinPageFrames = {}
end

function SkinPage:Update(playerInventory)
    SkinPage.Clear(self)
    
    local frames = {}

    if self._isPlayerAdmin then
        SkinPage.CreateSkinFramesForAllWeapons(self, frames)
    else
        SkinPage.CreateSkinFramesForAllDefaultWeapons(self, frames)
    end

    for _, unsplit in pairs(playerInventory.skin) do
        local invSkin = InventoryInterface2.ParseSkinString(unsplit)
        if frames[unsplit] then
            continue
        end
        
        local frame = SkinPage.CreateSkinFrame(self, unsplit)
        for i, v in pairs(invSkin) do
            frame:SetAttribute(i, v)
        end
        
        if playerInventory.equipped[invSkin.weapon] == unsplit then
            SkinPage.SetSkinFrameEquipped(self, frame, invSkin, true)
        end

        frames[unsplit] = frame
    end

    for _, unsplit in pairs(playerInventory.equipped) do
        local invSkin = InventoryInterface2.ParseSkinString(unsplit)
        if frames[unsplit] then
            SkinPage.SetSkinFrameEquipped(self, frames[unsplit], invSkin, true)
            continue
        end
        
        local frame = SkinPage.CreateSkinFrame(self, unsplit)
        for i, v in pairs(invSkin) do
            frame:SetAttribute(i, v)
        end
        
        frames[unsplit] = frame
    end

    self.SkinPageFrames = frames
end

function SkinPage:ConnectButtons()
    for _, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        table.insert(self.currentPageButtonConnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
            if not self.Location.Skin.Visible then return end
            SkinPage.SkinFrameButtonClicked(self, v)
        end))
    end
end

function SkinPage:CreateSkinFrame(skinStr)
    local invSkin = InventoryInterface2.ParseSkinString(skinStr):: InventoryInterface2.InventorySkinObject
    local displayName = Strings.firstToUpper(invSkin.model) .. " | " .. Strings.firstToUpper(invSkin.skin)

    local frame = self.Location.Skin.Content.ItemFrame:Clone()
    frame:WaitForChild("NameLabel").Text = displayName
    frame.Name = "SkinFrame_" .. displayName
    frame.Parent = self.Location.Skin.Content
    frame.BackgroundColor3 = frame:GetAttribute("unequippedColor")

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

function SkinPage:OpenItemDisplay(invSkin: InventoryInterface2.InventorySkinObject, skinFrame)
    if self.itemDisplayVar.active then return end
    self.itemDisplayVar.active = true -- turned off in CloseItemDisplay()

    self.itemDisplayFrame.ItemName.Text = Strings.firstToUpper(invSkin.model) .. " | " .. Strings.firstToUpper(invSkin.skin)
    self.itemDisplayFrame.IDLabel.Visible = true
    self.itemDisplayFrame.IDLabel.Text = "ID: " .. tostring(invSkin.uuid)
    
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
    model.Parent = self.itemDisplayFrame.CaseDisplay.ViewportFrame
    model.PrimaryPart = model:WaitForChild("GunComponents"):WaitForChild("WeaponHandle")
    model:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0,0,7)))
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
                Popup.burst("Successfully sold item for " .. tostring(shopItem.sell_sc) .. " SC!", 3)
                SkinPage.CloseItemDisplay(self)
                SkinPage.ConnectButtons(self)
                if isEquipped then
                    local defStr = InventoryInterface2.SetEquippedAsDefault(invSkin.weapon)
                    local defFrame = SkinPage.GetSkinFrame(self, invSkin.weapon, "default", 0)
                    SkinPage.SetSkinFrameEquipped(self, defFrame, InventoryInterface2.ParseSkinString(defStr), true)
                end
            else
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
    self.itemDisplayFrame.Visible = true
end

function SkinPage:CloseItemDisplay()
    self.itemDisplayVar.active = false
    for _, v in pairs(self.itemDisplayConns) do
        v:Disconnect()
    end
    self.itemDisplayFrame.Visible = false
    self.LastOpenPage.Visible = true
    self.Location.CasesButton.Visible = true
    self.Location.SkinsButton.Visible = true
    self.Location.KeysButton.Visible = true
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
    for _, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        if v:GetAttribute("weapon") == weapon and v:GetAttribute("skin") == skin and tostring(v:GetAttribute("uuid")) == tostring(uuid) then
            return v
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

return SkinPage
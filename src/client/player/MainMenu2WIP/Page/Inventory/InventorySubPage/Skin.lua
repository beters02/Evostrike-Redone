-- ENUM
local CustomWeaponPositions
CustomWeaponPositions = {
    Get = function(invSkin)
        local par = false
        if invSkin.weapon == "knife" then
            par = CustomWeaponPositions.knife[invSkin.model]
        else
            par = CustomWeaponPositions[invSkin.weapon]
        end
        return par
    end,

    knife = {
        vec = Vector3.new(1, 0, -3),
        karambit = {vec = Vector3.new(-0.026, -0.189, -1.399)},
        default = {vec = Vector3.new(0.143, -0.5, -2.1)},
        m9bayonet = {vec = Vector3.new(-0.029, -0, -1.674)},
    },
    glock17 = {vec = Vector3.new(0.15, 0.15, -1.4)},
    deagle = {vec = Vector3.new(0, 0, -1.5)},
    intervention = {vec = Vector3.new(0.5, 0, -7)},
    vityaz = {vec = Vector3.new(0.5,0,-2.3)}
}

-- CONFIG
config = {
    MaxFramesPerPage = 21
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local InventoryInterface2 = require(Framework.Module.InventoryInterface)
local Strings = require(Framework.shfc_strings.Location)
local ShopRarity = require(ReplicatedStorage.Assets.Shop.Rarity)
local ShopSkins = require(ReplicatedStorage.Assets.Shop.Skins)
local WeaponService = Framework.Service.WeaponService
local WeaponModules = WeaponService:WaitForChild("Weapon")
local PlayerData = require(Framework.Module.PlayerData)

local InventorySubPage = require(script.Parent)
local Skin = {}

function Skin:init(Inventory, Frame)
    Skin = setmetatable(InventorySubPage.new(Inventory, Frame, "Skin"), Skin)
    Skin.Var = {Equipping = false}

    Skin.EquippedSkinPageFrames = {}
    for i, _ in pairs(PlayerData:Get().ownedItems.equipped) do
        Skin.EquippedSkinPageFrames[i] = false
    end

    initItemDisplay(Skin)
end

function Skin:Open()
    InventorySubPage.Open(self)
    connectSkinFrames(self)
end

function Skin:Update()
    updateSkinFrames(self, PlayerData:Get().ownedItems)
end

-- Skin Item Frames
function updateSkinFrames(self, playerInventory)
    local frames = {[1] = {}} -- index per page number (pagesAmount)
    local skinsToCreate = {}
    local pagesAmount = 1
    local pageIndex = 1

    -- first we get all the skins in an array so we can count
    if self._isPlayerAdmin then
        skinsToCreate = getAllSkins()
    else
        skinsToCreate = getAllDefaultSkins()
    end
    for _, unsplit in pairs(playerInventory.skin) do
        table.insert(skinsToCreate, unsplit)
    end

    -- count for number of pages
    pagesAmount = math.ceil(#skinsToCreate/config.MaxFramesPerPage)
    self.ItemPageNumberVar.PageAmount = pagesAmount
    if pagesAmount > 1 then
        self:ConnectPageNumberButtons()
        for i = 2, pagesAmount+1 do
            self:AddContentFrame(i)
            frames[i] = {}
        end
    end

    -- add equipped skins
    for _, unsplit in pairs(playerInventory.equipped) do
        if #frames[pageIndex] >= config.MaxFramesPerPage then
            pageIndex += 1
        end

        local invSkin = InventoryInterface2.ParseSkinString(unsplit)
        local frame = createSkinFrame(self, unsplit, pageIndex)
        for i, v in pairs(invSkin) do
            frame:SetAttribute(i, v)
        end
        invSkin.frame = frame

        setSkinFrameEquipped(self, invSkin, true)
        table.insert(frames[pageIndex], {unsplit, frame})
    end

    -- add all other skins
    for _, unsplit in pairs(skinsToCreate) do
        if table.find(playerInventory.equipped, unsplit) then
            continue
        end
        if #frames[pageIndex] >= config.MaxFramesPerPage then
            pageIndex += 1
        end

        local invSkin = InventoryInterface2.ParseSkinString(unsplit)
        local frame = createSkinFrame(self, unsplit, pageIndex)
        for i, v in pairs(invSkin) do
            frame:SetAttribute(i, v)
        end
        table.insert(frames[pageIndex], {unsplit, frame})
    end

    self.SkinPageFrames = frames
end

function connectSkinFrames(self)
    for _, content in pairs(self.Frame:GetChildren()) do
        if content:IsA("Frame") and string.match(content.Name, "Content") then
            for _, v in pairs(content:GetChildren()) do
                if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
                table.insert(self.Connections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
                    if not self.Frame.Visible or not v.Parent.Visible then return end
                    skinFrameButtonClicked(self, v)
                end))
            end
        end
    end
end

function skinFrameButtonClicked(self, frame)
    local invSkin = getSkinFromFrame(frame)
    invSkin.frame = frame
    invSkin.rarity = frame:GetAttribute("rarity")

    self.ItemDisplay:ChangeDisplayedItem(invSkin)
    self:OpenItemDisplay()
end

function createSkinFrame(self, skinStr, pageIndex)
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

    local weaponModel = createSkinFrameModel(invSkin)
    weaponModel.Parent = frame:WaitForChild("ViewportFrame")
    frame.Visible = true
    return frame
end

function setSkinFrameEquipped(self, skinfo, ignoreUnequip)
    skinfo.frame.BackgroundColor3 = skinfo.frame:GetAttribute("equippedColor")
    skinfo.frame:SetAttribute("Equipped", true)
    if not ignoreUnequip then
        local currEquippedFrame = self.EquippedSkinPageFrames[skinfo.weapon]
        if currEquippedFrame then
            currEquippedFrame.BackgroundColor3 = currEquippedFrame:GetAttribute("unequippedColor")
            currEquippedFrame:SetAttribute("Equipped", false)
        end
    end
end

function createSkinFrameModel(invSkin)
    local weaponModelObj = InventoryInterface2.GetSkinModelFromSkinObject(invSkin):Clone()

    -- get model Inventory or Server
    local function move(target)
        target.Parent = weaponModelObj.Parent
        weaponModelObj:Destroy()
        weaponModelObj = target
    end

    if weaponModelObj:FindFirstChild("Inventory") then
        move(weaponModelObj.Inventory)
    elseif weaponModelObj:FindFirstChild("Server") then
        move(weaponModelObj.Server)
    end

    weaponModelObj.PrimaryPart = weaponModelObj.PrimaryPart or weaponModelObj.GunComponents.WeaponHandle

    -- get custom weapon positions
    local cf: CFrame = weaponModelObj.PrimaryPart.CFrame
    local pos = CustomWeaponPositions.Get(invSkin)
    pos = pos and pos.vec or Vector3.new(0.5,0,-3)
    weaponModelObj:SetPrimaryPartCFrame(CFrame.new(pos) * cf.Rotation)

    return weaponModelObj
end

function getAllSkins()
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

function getAllDefaultSkins()
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

function getSkinFromFrame(frame)
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

-- Item Display Frame
function initItemDisplay(self)
    Skin.ItemDisplay.Frame.MainButton.Text = "EQUIP"
    Skin.ItemDisplay.Frame.SecondaryButton.Text = "SELL"

    Skin.ItemDisplay.ClickedMainButton = function(itd)
        if setCurrentSkinEquipped(self) then
            itd.Frame.MainButton.Text = "EQUIPPED"
        end
    end

    Skin.ItemDisplay.ClickedSecondaryButton = function(itd)
        
    end

    Skin.ItemDisplay.ClickedBackButton = function(itd)
        
    end

    Skin.ItemDisplay.ChangeDisplayedItem = changeDisplayItem
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

    local model = itd:CreateSkinFrameModel(skinfo)
    model.Parent = itd.Frame.CaseDisplay.ViewportFrame
    model:SetPrimaryPartCFrame(model.PrimaryPart.CFrame + Vector3.new(0,0,7.8))

    itd.Var.CurrentSkinfo = skinfo
end

function setCurrentSkinEquipped(self, ignoreUnequip)
    if self.Var.Equipping then
        return false
    end
    self.Var.Equipping = true

    local skinfo = self.Var.CurrentSkinfo
    self.EquippedSkinPageFrames[skinfo.weapon] = skinfo.frame

    local succ, err = pcall(function()
        InventoryInterface2.SetEquippedSkinFromSkinObject(skinfo)
    end)
    if not succ then
        warn(err)
        self.Var.Equipping = false
        return false
    end

    

    self.Var.Equipping = false
    return true
end

return Skin
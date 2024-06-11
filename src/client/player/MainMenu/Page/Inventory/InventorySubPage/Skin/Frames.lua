local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local InventoryInterface2 = require(Framework.Module.InventoryInterface)
local Strings = require(Framework.shfc_strings.Location)
local ShopRarity = require(ReplicatedStorage.Assets.Shop.Rarity)
local ShopSkins = require(ReplicatedStorage.Assets.Shop.Skins)
local ShopInterface = require(Framework.Module.ShopInterface)
local WeaponService = Framework.Service.WeaponService
local WeaponModules = WeaponService:WaitForChild("Weapon")
local PlayerData = require(Framework.Module.PlayerData)
local Popup = require(script.Parent.Parent.Parent.Parent.Parent.Popup)
local Math = require(Framework.Module.lib.fc_math)
local EvoUI = require(Framework.Module.EvoUI)

local RightClickGui = ReplicatedStorage.Assets.UI:WaitForChild("RightClickGui")

local Frames = {}
local Config = require(script.Parent.Config)

function Frames.UpdateSkinFrames(self, playerInventory)
    playerInventory = playerInventory or PlayerData:Get().ownedItems

    for i, v in pairs(self.SkinPageFrames) do
        for k, a in pairs(v) do
            a[2]:Destroy()
            self.SkinPageFrames[i][k] = nil
        end
    end
    for i, v in pairs(self.EquippedSkinPageFrames) do
        if not v then continue end
        v:Destroy()
        self.EquippedSkinPageFrames[i] = nil
    end

    local frames = {[1] = {}} -- index per page number (pagesAmount)
    local skinsToCreate = {}
    local totalSkinsToCreate = 0
    local pagesAmount = 1
    local pageIndex = 1
    local createdStrings = {}

    -- first we get all the skins in an array so we can count
    if self._isPlayerAdmin then
        skinsToCreate = Frames.GetAllSkins()
    else
        skinsToCreate = Frames.GetAllDefaultSkins()
    end
    totalSkinsToCreate = #skinsToCreate

    for _, unsplit in pairs(playerInventory.skin) do
        table.insert(skinsToCreate, unsplit)
        totalSkinsToCreate += 1
    end
    for _, unsplit in pairs(playerInventory.equipped) do
        if string.match(unsplit, "default") then
            continue
        end
        totalSkinsToCreate += 1
    end

    -- count for number of pages
    pagesAmount = math.ceil(totalSkinsToCreate/Config.MaxFramesPerPage)
    self.ItemPageNumberVar.PageAmount = pagesAmount
    if pagesAmount > 1 then
        self:ConnectPageChangeButtons()
        for i = 2, pagesAmount+1 do
            self:AddContentFrame(i)
            frames[i] = {}
        end
    end

    -- add equipped skins
    for _, unsplit in pairs(playerInventory.equipped) do
        if #frames[pageIndex] >= Config.MaxFramesPerPage then
            pageIndex += 1
        end

        local invSkin = InventoryInterface2.ParseSkinString(unsplit)
        local frame = Frames.CreateSkinFrame(self, unsplit, pageIndex)
        for i, v in pairs(invSkin) do
            frame:SetAttribute(i, v)
        end
        invSkin.frame = frame

        Frames.SetSkinFrameEquipped(self, invSkin, true)
        table.insert(frames[pageIndex], {unsplit, frame})
        createdStrings[unsplit] = true
        self.EquippedSkinPageFrames[invSkin.weapon] = frame
    end

    -- add all other skins
    for _, unsplit in pairs(skinsToCreate) do
        if createdStrings[unsplit] then
            continue
        end
        if #frames[pageIndex] >= Config.MaxFramesPerPage then
            pageIndex += 1
        end

        local invSkin = InventoryInterface2.ParseSkinString(unsplit)
        local frame = Frames.CreateSkinFrame(self, unsplit, pageIndex)
        for i, v in pairs(invSkin) do
            frame:SetAttribute(i, v)
        end
        table.insert(frames[pageIndex], {unsplit, frame})
    end

    self.SkinPageFrames = frames
end

function Frames.ConnectSkinFrames(self)
    for _, content in pairs(self.Frame:GetChildren()) do
        if not content:IsA("Frame") or not string.match(content.Name, "Content") then
            continue
        end
        for _, itemFr in pairs(content:GetChildren()) do
            if not itemFr:IsA("Frame") or itemFr.Name == "ItemFrame" then
                continue
            end

            local button = itemFr:WaitForChild("Button")
            table.insert(self.SkinFrameConnections, button.MouseButton1Click:Connect(function()
                if not self.Frame.Visible or not itemFr.Parent.Visible then
                    return
                end
                Frames.OpenItemDisplayFromSkinFrame(self, itemFr)
                self.Frame.Visible = false
                self.Inventory:DisableSubPageButtons()
            end))
            table.insert(self.SkinFrameConnections, button.MouseButton2Click:Connect(function()
                if not self.Frame.Visible or not itemFr.Parent.Visible then
                    return
                end
                Frames.SkinFrameSecondaryClick(self, itemFr)
            end))
        end
    end
end

--@summary Skin Frame Primary Click
function Frames.OpenItemDisplayFromSkinFrame(self, frame)
    local invSkin = Frames.GetSkinFromFrame(frame)
    invSkin.frame = frame
    invSkin.rarity = frame:GetAttribute("rarity")

    self.ItemDisplay:ChangeDisplayedItem(invSkin)
    self:OpenItemDisplay()

    if frame:GetAttribute("Equipped") then
        self.ItemDisplay.Frame.MainButton.Text = "EQUIPPED"
    else
        self.ItemDisplay.Frame.MainButton.Text = "EQUIP"
    end

    self.CurrentOpenSkinFrame = frame
end

function Frames.SkinFrameSecondaryClick(self, frame)
    local equipped = frame:GetAttribute("Equipped")
    local rm = EvoUI.RightClickMenu.new(game.Players.LocalPlayer)

    if equipped then
        rm.Button1.Text = "EQUIPPED"
    else
        rm.Button1.Text = "EQUIP"
        rm.Button1Clicked = function()
            self:SetSkinEquipped(frame)
            rm:Destroy()
        end
    end

    rm.Button2.Text = "SELL"
    rm.Button2Clicked = function()
        self:SellSkin(frame)
        rm:Destroy()
    end

    rm:Enable()
end

function Frames.DisconnectSkinFrames(self)
    for _, v in pairs(self.SkinFrameConnections) do
        v:Disconnect()
    end
end

function Frames.CreateSkinFrame(self, skinStr, pageIndex)
    local invSkin = InventoryInterface2.ParseSkinString(skinStr):: InventoryInterface2.InventorySkinObject
    local displayName = Strings.firstToUpper(invSkin.model) .. " | " .. Strings.firstToUpper(invSkin.skin)

    local frame = self.Frame.Content1.ItemFrame:Clone()
    frame:WaitForChild("NameLabel").Text = displayName
    frame.Name = "SkinFrame_" .. displayName
    frame.Parent = self.Frame["Content" .. tostring(pageIndex)]
    frame.BackgroundColor3 = frame:GetAttribute("unequippedColor")

    local rarity = "Default"
    if (invSkin.weapon == "knife" and invSkin.model ~= "default") or (invSkin.weapon ~= "knife" and invSkin.skin ~= "default") then
        rarity = ShopSkins.GetSkinFromInvString(skinStr).rarity
    end

    frame:WaitForChild("RarityBar").BackgroundColor3 = ShopRarity[rarity].color

    frame:SetAttribute("rarity", rarity)
    frame:SetAttribute("weapon", invSkin.weapon)
    frame:SetAttribute("model", invSkin.model)
    frame:SetAttribute("skin", invSkin.skin)
    frame:SetAttribute("uuid", invSkin.uuid)
    frame:SetAttribute("Equipped", false)

    local viewport: ViewportFrame = frame:WaitForChild("ViewportFrame")
    local weaponModel = Frames.CreateSkinFrameModel(invSkin)
    weaponModel.Parent = viewport

    frame.Visible = true
    return frame
end

function Frames.CreateSkinFrameModel(invSkin)
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
    local posCfg = Config.enum.CustomWeaponPositions.Get(invSkin)

    local pos = Vector3.new(0.5,0,-3)
    local rot = cf.Rotation
    if posCfg then
        pos = posCfg.vec or pos
        if posCfg.rot then
            rot = CFrame.fromOrientation(posCfg.rot.X, posCfg.rot.Y, posCfg.rot.Z)
        end
    end

    weaponModelObj:SetPrimaryPartCFrame(CFrame.new(pos) * rot)
    return weaponModelObj
end

function Frames.SetSkinFrameEquipped(self, skinfo, ignoreUnequip)
    skinfo.frame:WaitForChild("EquippedCheckMark").Visible = true
    skinfo.frame:SetAttribute("Equipped", true)
    if not ignoreUnequip then
        local currEquippedFrame = self.EquippedSkinPageFrames[skinfo.weapon]
        if currEquippedFrame then
            currEquippedFrame:WaitForChild("EquippedCheckMark").Visible = false
            currEquippedFrame:SetAttribute("Equipped", false)
        end
    end
    self.EquippedSkinPageFrames[skinfo.weapon] = skinfo.frame
end

--@summary USE AT OWN RISK!
function Frames.GetSkinFrame(self, weapon, model, skin, uuid)
    if not weapon then
        return false
    end
    model = model or weapon
    uuid = uuid or 0
    skin = skin or "default"

    local str = weapon .. "_" .. model .. "_" .. skin .. "_" .. uuid

    for _, contentFr in pairs(self.Frame:GetChildren()) do
        if not contentFr:IsA("Frame") then continue end

        for _, itemFr in pairs(contentFr:GetChildren()) do
            if not itemFr:IsA("Frame") then continue end
            if itemFr:GetAttribute("unsplit") == str then
                return itemFr
            end
        end
    end
end

--@summary USE AT OWN RISK!
function Frames.GetDefaultWeaponSkinFrame(self, weapon)
    local unsplit
    if weapon == "knife" then
        unsplit = "knife_default_default_0"
    else
        unsplit = weapon .. "_" .. weapon .. "_default_0"
    end
    for _, contentFr in pairs(self.Frame:GetChildren()) do
        if not contentFr:IsA("Frame") then continue end

        for _, itemFr in pairs(contentFr:GetChildren()) do
            if not itemFr:IsA("Frame") then continue end
            if itemFr:GetAttribute("unsplit") == unsplit then
                return itemFr
            end
        end
    end
end

function Frames.GetAllSkins()
    local skins = {}
    for _, weaponFolder in pairs(WeaponModules:GetChildren()) do
        local weaponName = weaponFolder.Name

        local f = string.sub(weaponName, 1, 1)
        if f == "_" then
            continue
        end

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

function Frames.GetAllDefaultSkins()
    local skins = {}
    for _, weaponFolder in pairs(WeaponModules:GetChildren()) do
        if not weaponFolder:FindFirstChild("Assets") then
            continue
        end

        local f = string.sub(weaponFolder.Name, 1, 1)
        if f == "_" then
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

function Frames.GetSkinFromFrame(frame)
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

return Frames
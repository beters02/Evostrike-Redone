local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.shfc_strings.Location)
local InventoryInterface2 = require(Framework.Module.InventoryInterface)
local WeaponService = ReplicatedStorage:WaitForChild("Services"):WaitForChild("WeaponService")
local WeaponModules = WeaponService:WaitForChild("Weapon")
local PlayerData = require(Framework.Module.PlayerData)

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

    SkinPage.CreateSkinFramesForAllDefaultWeapons(self, frames)

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
    if skinFrame:GetAttribute("Equipped") then return end

    local invSkin = SkinPage.GetSkinFromFrame(self, skinFrame)
    local equippedInvSkin = InventoryInterface2.GetEquippedSkin(invSkin.weapon)
    if equippedInvSkin and equippedInvSkin.weapon == invSkin.weapon and equippedInvSkin.model == invSkin.model and equippedInvSkin.skin == invSkin.skin and equippedInvSkin.uuid == invSkin.uuid then
        return
    end

    InventoryInterface2.SetEquippedSkinFromSkinObject(invSkin)
    SkinPage.SetSkinFrameEquipped(self, skinFrame, invSkin)
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
        if v:GetAttribute("gunName") == weapon and v:GetAttribute("skinName") == skin and tostring(v:GetAttribute("uuid")) == tostring(uuid) then
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

function SkinPage:CreateSkinFramesForAllWeapons()
    for _, weaponFolder in pairs(WeaponModules:GetChildren()) do
        local weaponName = weaponFolder.Name

        local function initSkin(skinObject: any, weaponModelName)
            local inventoryKey = weaponModelName .. "_" .. skinObject.Name
            if weaponName == "knife" then inventoryKey = "knife_" .. inventoryKey end
            if not skinObject:GetAttribute("Ignore") and skinObject:IsA("Model") and skinObject.Name ~= "default" then
                SkinPage.CreateSkinFrame(self, inventoryKey)
            end
        end

        local modelsFolder = weaponName == "knife" and weaponFolder.Assets or weaponFolder.Assets.Models

        for _, model in pairs(modelsFolder:GetChildren()) do
            if model:GetAttribute("Ignore") or not model:IsA("Model") or model.Name == "default" then
                continue
            end

            if weaponName == "knife" then
                for _, knifeSkin in pairs(model.Models:GetChildren()) do
                    initSkin(knifeSkin, model.Name)
                end
                continue
            end

            initSkin(model, weaponName)
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
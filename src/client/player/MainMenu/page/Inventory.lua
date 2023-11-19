--[[
    When creating a new knife, make sure to init in the init function
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local InventoryInterface = require(Framework.shfc_inventoryPlayerDataInterface.Location)
local WeaponModules = game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("WeaponService"):WaitForChild("Weapon")
local WeaponService = require(Framework.Service.WeaponService)
local Strings = require(Framework.shfc_strings.Location)
local Cases = game.ReplicatedStorage.Assets.Cases
local ShopInterface = require(Framework.Module.ShopInterface)
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local TweenService = game:GetService("TweenService")

local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local AttemptOpenCaseGui = ShopAssets:WaitForChild("AttemptOpenCase")

local inventory = {}

function inventory:init()
    self.itemDisplayFrame = self.Location:WaitForChild("ItemDisplayFrame")
    self.itemDisplayVar = {active = false, caseOpeningActive = false}
    self.itemDisplayConns = {}
    self:Update()
    return self
end

function inventory:Open()
    self.Location.Visible = true
    self:ConnectButtons()
    self:OpenAnimations()
end

function inventory:Close()
    self.Location.Visible = false
    self:DisconnectButtons()
end

function inventory:Update(withClear: boolean?)
    print('Update Recieved!')
    if withClear then
        self:Clear()
    end

    local playerdata = PlayerData:UpdateFromServer(true)
    self._currentStoredInventory = playerdata.inventory.skin
    self._currentEquippedInventory = playerdata.inventory.equipped
    self._currentStoredCaseInventory = playerdata.inventory.case
    self._currentStoredKeyInventory = playerdata.inventory.key

    -- initialize all default skins as frames
    local _regwep = WeaponService:GetRegisteredWeapons()
    for i, v in pairs(_regwep) do
        if v == "knife" then
            for _, knife in pairs({"karambit", "m9bayonet", "butterfly"}) do
                for _, skin in pairs(self._currentStoredInventory) do
                    if string.match(knife, skin) or skin == "*" then
                        self:InitializeSkinStringAsFrame("knife_" .. knife .. "_default", 0)
                        break
                    end
                end
            end

            self:InitializeSkinStringAsFrame("knife_attackdefault_default", 0)
            continue
        end
        self:InitializeSkinStringAsFrame(v .. "_default", 0)
    end

    -- initialize player's skin inventory
    for id, v in pairs(self._currentStoredInventory) do
        if string.match(v, "case_") then continue end
        if v == "*" then
            self:CreateSkinFrame(false, false, false, false, true)
        elseif string.match(v, "*") then
            continue
        else
            self:InitializeSkinStringAsFrame(v, id)
        end
    end

    -- initialize player's case inventory
    for _, v: string in pairs(self._currentStoredCaseInventory) do
        self:CreateCaseFrame(v:gsub("case_", ""))
    end

    -- init player's key inventory
    for _, v: string in pairs(self._currentStoredKeyInventory) do
        self:CreateKeyFrame(v:gsub("key_", ""))
    end
end

function inventory:Clear()
    for _, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "ItemFrame" then
            v:Destroy()
        end
    end
    for _, v in pairs(self.Location.Case.Content:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "ItemFrame" then
            v:Destroy()
        end
    end
end

--
function inventory:ConnectButtons()
    self._bconnections = {}

    self._bconnections.openskin = self.Location.SkinsButton.MouseButton1Click:Connect(function()
        if self.Location.Skin.Visible or not self.Location.SkinsButton.Visible then
            return
        end
        self:OpenSkinPage()
    end)

    self._bconnections.opencase = self.Location.CasesButton.MouseButton1Click:Connect(function()
        if self.Location.Case.Visible or not self.Location.CasesButton.Visible then
            return
        end
        self:OpenCasePage()
    end)

    self._bconnections.openkey = self.Location.KeysButton.MouseButton1Click:Connect(function()
        if self.Location.Key.Visible or not self.Location.KeysButton.Visible then
            return
        end
        self:OpenKeyPage()
    end)

    -- connect skin buttons
    for _, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        table.insert(self._bconnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
            if not self.Location.Skin.Visible then return end
            self:SkinButtonClicked(v)
        end))
    end

    -- connect case buttons
    for _, v in pairs(self.Location.Case.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        table.insert(self._bconnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
            if not self.Location.Case.Visible then return end
            self:CaseButtonClicked(v)
        end))
    end

    --TODO: connect key buttons
end

function inventory:DisconnectButtons()
    for _, v in pairs(self._bconnections) do
        v:Disconnect()
    end
    self._bconnections = {}
end

-- [[ ITEM DISPLAY ]]
function inventory:OpenItemDisplay(caseFrame)
    if self.itemDisplayVar.active then return end
    self.itemDisplayVar.active = true -- turned off in CloseItemDisplay()

    self.itemDisplayFrame.CaseDisplay.Visible = true
    self.itemDisplayFrame.ItemDisplayImageLabel.Visible = false
    local itemDisplayName = caseFrame:GetAttribute("ItemDisplayName") or caseFrame.Name
    self.itemDisplayFrame.ItemName.Text = string.upper(itemDisplayName)
    self.itemDisplayFrame.MainButton.Text = "OPEN"

    self.itemDisplayConns.MainButton = self.itemDisplayFrame.MainButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.caseOpeningActive then
            return
        end
        self.itemDisplayVar.caseOpeningActive = true
        self:OpenCaseButtonClicked(caseFrame)
        self.itemDisplayVar.caseOpeningActive = false
    end)

    self.itemDisplayConns.BackButton = self.itemDisplayFrame.BackButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.caseOpeningActive then
            return
        end
        self:CloseItemDisplay()
    end)

    self.LastOpenPage = self.Location.Case.Visible and self.Location.Case or self.Location.Skin
    self.Location.Case.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.Visible = false
    self.Location.SkinsButton.Visible = false
    self.itemDisplayFrame.Visible = true
end

function inventory:CloseItemDisplay()
    self.itemDisplayVar.active = false
    self.itemDisplayConns.MainButton:Disconnect()
    self.itemDisplayConns.BackButton:Disconnect()
    self.itemDisplayFrame.Visible = false
    self.LastOpenPage.Visible = true
end

-- [[ SKIN PAGE ]]
function inventory:OpenSkinPage()
    self.Location.Case.Visible = false
    self.Location.Key.Visible = false
    self.Location.Skin.Visible = true
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

function inventory:CreateSkinFrame(weapon: string, skin: string, model: string|nil, isEquipped: boolean|nil, allSkins: boolean?, uuid: number?)
    local frame
    local weaponModelObj
    local displayName

    -- check if player has access to all skins
    -- if so, we recurse CreateSkinFrame until all skins (except default) are added.
    if allSkins then
        for _, weaponFolder in pairs(game:GetService("ReplicatedStorage").Services.WeaponService.Weapon:GetChildren()) do
            local weaponAssets = weaponFolder.Assets

            if weaponAssets.Parent.Name == "knife" then
                for _, knifeFolder in pairs(weaponAssets:GetChildren()) do
                    for _, v in pairs(knifeFolder.Models:GetChildren()) do
                        if not v:GetAttribute("Ignore") and v:IsA("Model") and v.Name ~= "default" then
                            self:InitializeSkinStringAsFrame("knife" .. "_" .. knifeFolder.Name .. "_" .. v.Name, 0)
                        end
                    end
                end
            else
                for _, v in pairs(weaponAssets.Models:GetChildren()) do
                    if not v:GetAttribute("Ignore") and v:IsA("Model") and v.Name ~= "default" then
                        local _str = weaponFolder.Name .. "_" .. v.Name
                        self:InitializeSkinStringAsFrame(_str, 0)
                    end
                end
            end
        end
        return
    else
    
        -- check if player has access to all skins to a specific weapon
        -- if so, we recurse CreateSkinFrame until all skins are added.
        local parent = weapon == "knife" and WeaponModules.knife.Assets:WaitForChild(model).Models or WeaponModules:WaitForChild(weapon).Assets.Models
        if skin == "*" then
            for _, v in pairs(parent:GetChildren()) do
                if not v:IsA("Model") or v.Name == "default" or v:GetAttribute("Ignore") then continue end
                local _str = model and weapon .. "_" .. model .. "_" .. v.Name or weapon .. "_" .. skin
                self:InitializeSkinStringAsFrame(_str, 0)
            end
            return
        end
    end

    if weapon == "knife" then
        weaponModelObj = WeaponModules.knife.Assets:WaitForChild(model).Models:WaitForChild(skin)
        displayName = (model == "attackdefault" and "Attack Default Knife") or (model == "defenddefault" and "Defend Default Knife") or Strings.firstToUpper(model)
    else
        weaponModelObj = WeaponModules:WaitForChild(weapon).Assets.Models:WaitForChild(skin)
        displayName = Strings.firstToUpper(weapon)
    end

    -- add skin to display name
    displayName = displayName .. " | " .. Strings.firstToUpper(skin)

    -- create frame clone
    frame = self.Location.Skin.Content.ItemFrame:Clone()
    frame.Name = "SkinFrame_" .. displayName
    frame.Parent = self.Location.Skin.Content

    -- if model == defaultattack or defaultdefend, set back to default
    if model and model ~= "default" and string.match(model, "default") then
        model = "default"
    end

    frame:SetAttribute("gunName", weapon)
    frame:SetAttribute("skinName", model and model.."_"..skin or skin)
    frame:SetAttribute("uuid", uuid)

    -- set labels
    frame:WaitForChild("NameLabel").Text = displayName

    -- add weapons to viewport (this shit sucks)
    weaponModelObj = weaponModelObj:Clone()
    if weaponModelObj:FindFirstChild("Server") then
        local server = weaponModelObj.Server
        server.Parent = weaponModelObj.Parent
        weaponModelObj:Destroy()
        weaponModelObj = server
    end

    weaponModelObj.PrimaryPart = weaponModelObj.GunComponents.WeaponHandle

    local wepcf = CFrame.new(Vector3.new(1,0,-4))
    local wepor = Vector3.new(90, 0, 0)
    
    if weapon == "knife" then
        if model == "karambit" then
            wepcf = CFrame.new(Vector3.new(-0.026, -0.189, -1.399))
        elseif model == "default" then
            wepcf = CFrame.new(Vector3.new(0.143, -0.5, -2.1))
            wepor = Vector3.new(0, 180, 180)
        elseif model == "m9bayonet" then
            wepcf = CFrame.new(Vector3.new(-0.029, -0, -1.674))
        else
            wepcf = CFrame.new(Vector3.new(1, 0, -3))
        end
    elseif weapon == "ak47" then
        wepor = Vector3.new(90, 170, 0)
    elseif weapon == "deagle" then
        wepcf = CFrame.new(Vector3.new(-0.1, 0, -1.5))
        wepor = Vector3.new(0, -180, -180)
    elseif weapon == "glock17" then
        wepcf = CFrame.new(Vector3.new(-0.4, 0.2, -1.4))
        wepor = Vector3.new(0, 90, -180)
    end

    weaponModelObj:SetPrimaryPartCFrame(wepcf)
    weaponModelObj.PrimaryPart.Orientation = wepor
    weaponModelObj.Parent = frame:WaitForChild("ViewportFrame")-- maybe add a world model?

    -- set frame colors based on equipped
    self:SetSkinFrameEquipped(frame, isEquipped, weapon, false, true)

    frame.Visible = true
    return frame
end

function inventory:CreateSkinFrameModel(weapon: string, knifeModel: string, skin: string)
    if weapon == "knife" then
        weaponModelObj = WeaponModules.knife.Assets:WaitForChild(knifeModel).Models:WaitForChild(skin)
        displayName = (knifeModel == "attackdefault" and "Attack Default Knife") or (knifeModel == "defenddefault" and "Defend Default Knife") or Strings.firstToUpper(knifeModel)
    else
        weaponModelObj = WeaponModules:WaitForChild(weapon).Assets.Models:WaitForChild(skin)
        displayName = Strings.firstToUpper(weapon)
    end

    -- if model == defaultattack or defaultdefend, set back to default
    if knifeModel and knifeModel ~= "default" and string.match(knifeModel, "default") then
        knifeModel = "default"
    end

    -- add weapons to viewport (this shit sucks)
    weaponModelObj = weaponModelObj:Clone()
    if weaponModelObj:FindFirstChild("Server") then
        local server = weaponModelObj.Server
        server.Parent = weaponModelObj.Parent
        weaponModelObj:Destroy()
        weaponModelObj = server
    end

    weaponModelObj.PrimaryPart = weaponModelObj.GunComponents.WeaponHandle

    local wepcf = CFrame.new(Vector3.new(1,0,-4))
    local wepor = Vector3.new(90, 0, 0)
    
    if weapon == "knife" then
        if knifeModel == "karambit" then
            wepcf = CFrame.new(Vector3.new(-0.026, -0.189, -1.399))
        elseif knifeModel == "default" then
            wepcf = CFrame.new(Vector3.new(0.143, -0.5, -2.1))
            wepor = Vector3.new(0, 180, 180)
        elseif knifeModel == "m9bayonet" then
            wepcf = CFrame.new(Vector3.new(-0.029, -0, -1.674))
        else
            wepcf = CFrame.new(Vector3.new(1, 0, -3))
        end
    elseif weapon == "ak47" then
        wepor = Vector3.new(90, 170, 0)
    elseif weapon == "deagle" then
        wepcf = CFrame.new(Vector3.new(-0.1, 0, -1.5))
        wepor = Vector3.new(0, -180, -180)
    elseif weapon == "glock17" then
        wepcf = CFrame.new(Vector3.new(-0.4, 0.2, -1.4))
        wepor = Vector3.new(0, 90, -180)
    end

    weaponModelObj:SetPrimaryPartCFrame(wepcf)
    weaponModelObj.PrimaryPart.Orientation = wepor
    return weaponModelObj
end

function inventory:GetSkinFrame(weapon: string, skin: string, uuid)
    for _, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        if v:GetAttribute("gunName") == weapon and v:GetAttribute("skinName") == skin and tostring(v:GetAttribute("uuid")) == tostring(uuid) then
            return v
        end
    end
    return false
end

-- Will automatically set currently equipped to unequipped during SetSkinFrameEquipped(any, any, any, true)
function inventory:SetSkinFrameEquipped(skinFrame, equipped, weapon, previousSkinfo, ignoreUnequip)
    if equipped then
        self:SetSkinFrameEquipped(false, false, weapon, previousSkinfo, ignoreUnequip)
        skinFrame:SetAttribute("Equipped", true)
        -- Set frame gui to be equipped
        skinFrame.BackgroundColor3 = skinFrame:GetAttribute("equippedColor")
    else
        local _prev = skinFrame
        if not _prev then
            if ignoreUnequip then return end
            _prev = weapon == "knife" and previousSkinfo.model.."_"..previousSkinfo.skin or previousSkinfo.skin
            _prev = self:GetSkinFrame(weapon, _prev, previousSkinfo.uuid)
        end
        if not _prev then
            warn("Could not find previous skin frame to unequip")
            return
        end
        _prev.BackgroundColor3 = _prev:GetAttribute("unequippedColor")
        _prev:SetAttribute("Equipped", false)
    end
end

function inventory:SkinButtonClicked(skinFrame)
    local weapon = skinFrame:GetAttribute("gunName")
    local skin = skinFrame:GetAttribute("skinName")
    local uuid = skinFrame:GetAttribute("uuid")

    -- Check already equipped
    if skinFrame:GetAttribute("Equipped") then return end

    local equippedSkinfo = InventoryInterface:GetEquippedWeaponSkin(self.player, weapon)
    if equippedSkinfo.model and equippedSkinfo.model .. "_" .. equippedSkinfo.skin == skin and equippedSkinfo.uuid == uuid then
        return
    end
    if equippedSkinfo.skin == skin and equippedSkinfo.uuid == uuid then
        return
    end

    -- Set equipped
    local success, err = InventoryInterface:SetEquippedWeaponSkin(self.player, weapon, skin, uuid)
    if not success then error(err) end

    self:SetSkinFrameEquipped(skinFrame, true, weapon, equippedSkinfo)
end

function inventory:InitializeSkinStringAsFrame(skinString: string, uuid: number)
    local _sep = skinString:split("_")
    local _equipped = false

    if #_sep == 3 then

        -- if this is the skin that the player has equipped, send the data (knife)
        if self._currentEquippedInventory.knife == _sep[2] .. "_" .. _sep[3] .. "_" .. tostring(uuid) or (self._currentEquippedInventory.knife == "default_default" and string.match(_sep[2], "default") and _sep[3] == "default") then
            _equipped = true
        end

        self:CreateSkinFrame(_sep[1], _sep[3], _sep[2], _equipped, false, uuid)
        return
    end

    -- same here (guns)
    if self._currentEquippedInventory[_sep[1]] == _sep[2] .. "_" .. tostring(uuid) then
        _equipped = true
    end

    self:CreateSkinFrame(_sep[1], _sep[2], nil, _equipped, false, uuid)
end

-- [[ CASE PAGE ]]
function inventory:OpenCasePage()
    self.Location.Case.Visible = true
    self.Location.Key.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

function inventory:CreateCaseFrame(case: string)
    local caseFolder = Cases:FindFirstChild(string.lower(case))
    if not caseFolder then
        warn("Could not find CaseFolder for case " .. tostring(case))
        return
    end

    local itemFrame = self.Location.Case.Content.ItemFrame:Clone()
    local itemModel = caseFolder.DisplayFrame.Model:Clone()
    itemModel.Parent = itemFrame:WaitForChild("ViewportFrame")
    itemModel:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 0, -5)))

    itemFrame.Name = "SkinFrame_" .. string.lower(case)
    itemFrame:WaitForChild("NameLabel").Text = caseFolder:GetAttribute("DisplayName") or case
    itemFrame.NameLabel.Text = string.upper(itemFrame.NameLabel.Text)
    itemFrame.Visible = true
    itemFrame.Parent = self.Location.Case.Content
    itemFrame:SetAttribute("CaseName", string.lower(case))
    return itemFrame
end

function inventory:CaseButtonClicked(caseFrame)
    self:OpenItemDisplay(caseFrame)
end

function inventory:OpenCaseButtonClicked(caseFrame)
    local caseName = caseFrame:GetAttribute("CaseName")

    -- Confirm Case Open/Key Purchase
    local hasKey = ShopInterface:HasKey(caseName)
    local hasConfirmed = false
    local confirmGui = AttemptOpenCaseGui:Clone()
    local keyAcceptButton = confirmGui:WaitForChild("Frame"):WaitForChild("KeyAcceptButton")
    CollectionService:AddTag(confirmGui, "CloseItemDisplay")
    
    if hasKey then
        keyAcceptButton.Text = "use key"
        confirmGui.Frame.KeyNotOwnedLabel.Visible = false
    else
        keyAcceptButton.Text = "purchase key"
        confirmGui.Frame.KeyNotOwnedLabel.Visible = true
    end

    self.itemDisplayConns.CaseConfirmation = keyAcceptButton.MouseButton1Click:Connect(function()
        if hasConfirmed then return end
        hasConfirmed = true
        if hasKey then
            local openedSkin, potentialSkins
            local success, result = pcall(function()
                openedSkin, potentialSkins = ShopInterface:OpenCase(caseName)
            end)
            if success then
                task.spawn(function()
                    self:OpenCase(openedSkin, potentialSkins)
                end)
            else
                Popup.burst(tostring(result), 3)
            end
        else
            self._mainPageModule:OpenPage("Shop")
        end
        confirmGui:Destroy()
        self.itemDisplayConns.CaseConfirmation:Disconnect()
    end)

    confirmGui.Parent = game.Players.LocalPlayer.PlayerGui
end

-- [[ KEY PAGE ]]
function inventory:OpenKeyPage()
    self.Location.Case.Visible = false
    self.Location.Key.Visible = true
    self.Location.Skin.Visible = false
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

function inventory:CreateKeyFrame(case: string)
    local caseFolder = Cases:FindFirstChild(string.lower(case))
    if not caseFolder then
        warn("Could not find CaseFolder for case " .. tostring(case))
        return
    end

    local itemFrame = self.Location.Key.Content.ItemFrame:Clone()
    local itemModel = caseFolder.DisplayFrame.Model:Clone()
    itemModel.Parent = itemFrame:WaitForChild("ViewportFrame")
    itemModel:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 0, -5)))

    itemFrame.Name = "SkinFrame_" .. string.lower(case)
    itemFrame:WaitForChild("NameLabel").Text = caseFolder:GetAttribute("DisplayName") or case
    itemFrame.NameLabel.Text = string.upper(itemFrame.NameLabel.Text) .. " KEY"
    itemFrame.Visible = true
    itemFrame.Parent = self.Location.Key.Content
    itemFrame:SetAttribute("CaseName", string.lower(case))
    return itemFrame
end


-- [[ CASE OPENING SEQUENCE ]]

function inventory:OpenCase(gotSkin, potentialSkins)
    self.itemDisplayVar.caseOpeningActive = true
    self:CloseItemDisplay()

    -- Prepare Var & Tween
    local crates = self.Location.CaseOpeningSequence.CaseDisplay.ViewportFrame.Crates
    local endCF = crates.PrimaryPart.CFrame - Vector3.new(0, 0, 1)
    local GrowTween = TweenService:Create(crates.PrimaryPart, TweenInfo.new(1), {CFrame = endCF})
    local WheelTween = TweenService:Create(self.Location.CaseOpeningSequence.ItemWheelDisplay.Wheel, TweenInfo.new(3, Enum.EasingStyle.Quad), {CanvasPosition = Vector2.new(2150, 0)})

    -- Fill Wheel CaseFrames with Models
    self:FillCaseFrame(1, gotSkin)
    local count = 1
    for _, v in pairs(potentialSkins) do
        count += 1
        self:FillCaseFrame(count, v)
    end

    -- Play Grow Tween
    self.Location.CaseOpeningSequence.CaseDisplay.Visible = true
    self.Location.CaseOpeningSequence.ItemWheelDisplay.Visible = false
    self.Location.CaseOpeningSequence.Visible = true
    GrowTween:Play()
    GrowTween.Completed:Wait()
    
    -- Play Wheel Tween
    self.Location.CaseOpeningSequence.CaseDisplay.Visible = false
    self.Location.CaseOpeningSequence.ItemWheelDisplay.Visible = true
    WheelTween:Play()
    WheelTween.Completed:Wait()

    -- play Received Item Screen
    task.delay(1, function()
        self:OpenCasePage()
        self.Location.CaseOpeningSequence.Visible = false
    end)
end

function inventory:FillCaseFrame(index, skin)
    local itemFrame = self.Location.CaseOpeningSequence.ItemWheelDisplay.Wheel["Item_" .. index]
    local model = self:CreateSkinFrameModel(skin.weapon, skin.knifeModel, skin.index)
    model.Parent = itemFrame:WaitForChild("ViewportFrame")
end

return inventory
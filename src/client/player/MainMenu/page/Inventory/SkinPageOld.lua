local inventory = {}

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
    local displayName
    local weaponModel

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

    -- create weapon model
    weaponModel = self:CreateSkinFrameModel(weapon, model, skin)
    weaponModel.Parent = frame:WaitForChild("ViewportFrame")

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

return inventory
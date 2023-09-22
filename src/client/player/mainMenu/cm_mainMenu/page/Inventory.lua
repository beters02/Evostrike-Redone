local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.shm_clientPlayerData.Location)
local InventoryInterface = require(Framework.shfc_inventoryPlayerDataInterface.Location)
local WeaponObjects = game:GetService("ReplicatedStorage"):WaitForChild("weapon"):WaitForChild("obj")
local WeaponGetRemote = WeaponObjects.Parent:WaitForChild("remote"):WaitForChild("get")
local Strings = require(Framework.shfc_strings.Location)

local inventory = {}

function inventory:init()
    self._currentStoredInventory = {}

    -- first, we connect the changed (skin added/removed) listener
    PlayerData:Changed("inventory.skin", function(newValue, properties)
        if not properties then return end

        if properties.isInsert then
            -- insert skin frame
        elseif properties.isRemove then
            -- remove skin frame
        end
    end)

    -- then we grab the player's inventory
    self._currentStoredInventory = PlayerData:Get("inventory.skin")
    self._currentEquippedInventory = PlayerData:Get("inventory.equipped")

    -- initialize all default skins as frames
    -- first check if player has all skins
    local initAll = false
    for i, v in pairs(self._currentStoredInventory)do
        if v == "*" then
            self:CreateSkinFrame(false, false, false, false, true)
            initAll = true
            break
        end
    end

    local _regwep = WeaponGetRemote:InvokeServer("GetRegisteredWeapons")
    for i, v in pairs(_regwep) do
        if v == "knife" then
            --self:InitializeSkinStringAsFrame("knife_defenddefault_default")
            self:InitializeSkinStringAsFrame("knife_attackdefault_default")
            self:InitializeSkinStringAsFrame("knife_karambit_default")
            self:InitializeSkinStringAsFrame("knife_m9bayonet_default")
            continue
        end
        self:InitializeSkinStringAsFrame(v .. "_default")
    end

    -- initialize all player skins as frames
    if not initAll then
        for i, v in pairs(self._currentStoredInventory) do
            self:InitializeSkinStringAsFrame(v)
        end
    end

    -- done!
    return self
end

function inventory:Open()
    self.Location.Visible = true
    self:ConnectButtons()
end

function inventory:Close()
    self.Location.Visible = false
    self:DisconnectButtons()
end

function inventory:ConnectButtons()
    self._bconnections = {}
    for i, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        table.insert(self._bconnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
            self:SkinButtonClicked(v)
        end))
    end
end

function inventory:DisconnectButtons()
    for i, v in pairs(self._bconnections) do
        v:Disconnect()
    end
    self._bconnections = {}
end

--

function inventory:CreateSkinFrame(weapon: string, skin: string, model: string|nil, isEquipped: boolean|nil, allSkins: boolean?)
    local frame
    local weaponModelObj
    local displayName

    -- check if player has access to all skins
    -- if so, we recurse CreateSkinFrame until all skins (except default) are added.
    if allSkins then

        for _, weaponFolder in pairs(game:GetService("ReplicatedStorage").weapon.obj:GetChildren()) do
            if weaponFolder.Name == "global" then continue end

            for i, v in pairs(weaponFolder.models:GetChildren()) do
                if not v:GetAttribute("Ignore") and v:IsA("Model") and v.Name ~= "default" then
                    local _str = string.match(weaponFolder.Name, "knife") and "knife" .. "_" .. string.split(weaponFolder.Name, "_")[2] .. "_" .. v.Name or weaponFolder.Name .. "_" .. v.Name
                    self:InitializeSkinStringAsFrame(_str)
                end
            end
        end

        return
    else
    
        -- check if player has access to all skins to a specific weapon
        -- if so, we recurse CreateSkinFrame until all skins are added.
        local parent = weapon == "knife" and WeaponObjects:WaitForChild("knife_" .. model):WaitForChild("models") or WeaponObjects:WaitForChild(weapon):WaitForChild("models")
        if skin == "*" then
            for i, v in pairs(parent:GetChildren()) do
                if not v:IsA("Model") or v.Name == "default" or v:GetAttribute("Ignore") then continue end
                local _str = model and weapon .. "_" .. model .. "_" .. v.Name or weapon .. "_" .. skin
                self:InitializeSkinStringAsFrame(_str)
            end
            return
        end
    
    end

    if weapon == "knife" then
        weaponModelObj = WeaponObjects:WaitForChild("knife_" .. model):WaitForChild("models"):WaitForChild(skin)
        displayName = (model == "attackdefault" and "Attack Default Knife") or (model == "defenddefault" and "Defend Default Knife") or Strings.firstToUpper(model)
    else
        weaponModelObj = WeaponObjects:WaitForChild(weapon):WaitForChild("models"):WaitForChild(skin)
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

function inventory:GetSkinFrame(weapon: string, skin: string)
    for i, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        if v:GetAttribute("gunName") == weapon and v:GetAttribute("skinName") == skin then
            return v
        end
    end
    return false
end

-- Changes the visual elements of a skin frame to be Equipped or Unequipped
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
            _prev = self:GetSkinFrame(weapon, _prev)
        end
        if not _prev then
            warn("Could not find previous skin frame to unequip")
            return
        end
        _prev.BackgroundColor3 = _prev:GetAttribute("unequippedColor")
        _prev:SetAttribute("Equipped", false)
    end
end

--

function inventory:SkinButtonClicked(skinFrame)
    local weapon = skinFrame:GetAttribute("gunName")
    local skin = skinFrame:GetAttribute("skinName")

    -- Check already equipped
    if skinFrame:GetAttribute("Equipped") then return end

    local equippedSkinfo = InventoryInterface:GetEquippedWeaponSkin(self.player, weapon)
    if (equippedSkinfo.model and equippedSkinfo.model .. "_" .. equippedSkinfo.skin == skin) or equippedSkinfo.skin == skin then
        return
    end

    -- Set equipped
    local success, err = InventoryInterface:SetEquippedWeaponSkin(self.player, weapon, skin)
    if not success then error(err) end

    self:SetSkinFrameEquipped(skinFrame, true, weapon, equippedSkinfo)
end

--[[
    @title InitializeSkinStringAsFrame
    @summary Automatically inintialize a skinString "weapon_modelName_skinName" as a frame with the equipped data set.
]]
function inventory:InitializeSkinStringAsFrame(skinString: string)
    local _sep = skinString:split("_")
    local _equipped = false

    if #_sep == 3 then

        -- if this is the skin that the player has equipped, send the data (knife)
        if self._currentEquippedInventory.knife == _sep[2] .. "_" .. _sep[3] or (self._currentEquippedInventory.knife == "default_default" and string.match(_sep[2], "default") and _sep[3] == "default") then
            _equipped = true
        end

        self:CreateSkinFrame(_sep[1], _sep[3], _sep[2], _equipped)
        return
    end

    -- same here (guns)
    if self._currentEquippedInventory[_sep[1]] == _sep[2] then
        _equipped = true
    end

    self:CreateSkinFrame(_sep[1], _sep[2], nil, _equipped)
end

return inventory
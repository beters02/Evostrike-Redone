local RunService = game:GetService("RunService")
if RunService:IsServer() then
    return require(script:WaitForChild("Server"))
end

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local WeaponService = require(Framework.Service.WeaponService)

local InventoryInterface = {}

local Shared = require(script:WaitForChild("Shared"))
for i, v in pairs(Shared) do
    InventoryInterface[i] = v
end

export type InventorySkinObject = Shared.InventorySkinObject

function InventoryInterface.GetEquippedSkin(weapon: string)
    local skinStr = PlayerData:Get().ownedItems.equipped[weapon]
    return Shared.ParseSkinString(skinStr)
end

function InventoryInterface.SetEquippedSkinFromSkinObject(skin)
    PlayerData:SetPath("ownedItems.equipped." .. skin.weapon, skin.unsplit)
    PlayerData:Save()
end

function InventoryInterface.SetEquippedSkinFromString(skinStr)
    PlayerData:SetPath("ownedItems.equipped." .. Shared.ParseSkinString(skinStr).weapon, skinStr)
    PlayerData:Save()
end

function InventoryInterface.GetSkinModelFromSkinObject(skin) -- Returns Default Skin if Necessary
    print(skin)
    local weaponModule = WeaponService:GetWeaponModule(skin.weapon)
    local success, model = pcall(function()
        if skin.weapon == "knife" then
            return weaponModule.Assets[skin.model].Models[skin.skin]
        end
        return weaponModule.Assets.Models[skin.skin]
    end)
    if success then
        return model
    end
    warn("Could not find skin for model " .. tostring(skin.weapon) .. "_" .. tostring(skin.skin) .. ". " .. tostring(model))
    return InventoryInterface.GetDefaultSkinForWeapon(skin.weapon)
end

function InventoryInterface.GetDefaultSkinForWeapon(weapon)
    if weapon == "knife" then
        return WeaponService:GetWeaponModule("knife").Assets.default.Models.default
    end
    return WeaponService:GetWeaponModule(weapon).Assets.Models.default
end

function InventoryInterface.GetSkinModelFromString(skinStr)
    return InventoryInterface.GetSkinModelFromSkinObject(Shared.ParseSkinString(skinStr))
end

return InventoryInterface
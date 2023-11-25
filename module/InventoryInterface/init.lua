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

function InventoryInterface.SetEquippedAsDefault(weapon)
    local defStr = Shared.GetDefaultSkinStrForWeapon(weapon)
    PlayerData:SetPath("ownedItems.equipped." .. weapon, defStr)
    PlayerData:Save()
    return defStr
end

return InventoryInterface
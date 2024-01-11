
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local SkinsDatabase = require(game:GetService("ServerStorage").SkinsDatabase)
local AssetService = game:GetService("AssetService")

local Server = {}
local Shared = require(script.Parent:WaitForChild("Shared"))
for i, v in pairs(Shared) do
    Server[i] = v
end

function Server.GetEquippedSkin(player: Player, weapon: string)
    local skinStr = PlayerData:Get(player).ownedItems.equipped[weapon]
    local skin = Shared.ParseSkinString(skinStr)
    local skinData

    if weapon == "knife" then
        skinData = SkinsDatabase:GetSkin(skin)
    end

    return skin, skinData
end

function Server.SetEquippedSkin(player: Player, skin)
    PlayerData:SetPath(player, "ownedItems.equipped." .. skin.weapon, skin.unsplit)
    PlayerData:Save(player)
end

function Server.SetEquippedSkinFromSkinObject(player, skin)
    PlayerData:SetPath(player, "ownedItems.equipped." .. skin.weapon, skin.unsplit)
    PlayerData:Save(player)
end

function Server.SetEquippedSkinFromString(player, skinStr)
    PlayerData:SetPath(player, "ownedItems.equipped." .. Shared.ParseSkinString(skinStr).weapon, skinStr)
    PlayerData:Save(player)
end

function Server.SetEquippedAsDefault(player, weapon)
    PlayerData:SetPath(player, "ownedItems.equipped." .. weapon, Shared.GetDefaultSkinStrForWeapon(weapon))
    PlayerData:Save(player)
end

function Server.GetSkinData(player, skin)
    local dbskin = SkinsDatabase:GetSkin(skin)
    print(dbskin)
    return dbskin
end

function Server.ApplySkinDataToModel(model, skinData: SkinsDatabase.DatabaseSkin)
    for _, sa in pairs(model:GetDescendants()) do
        if sa:IsA("SurfaceAppearance") then
            sa = sa:: SurfaceAppearance
            for _, mapStr in pairs({"Color", "Metalness", "Normal", "Roughness"}) do
                local newimg = AssetService:CreateEditableImageAsync(sa[mapStr.."Map"])
                newimg:Rotate(math.rad(skinData.Seed))
                --newimg:
                -- apply wear here
            end
        end
    end
end

return Server
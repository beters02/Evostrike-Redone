
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

local Server = {}
local Shared = require(script.Parent:WaitForChild("Shared"))
for i, v in pairs(Shared) do
    Server[i] = v
end

function Server.GetEquippedSkin(player: Player, weapon: string)
    local skinStr = PlayerData:Get(player).ownedItems.equipped[weapon]
    return Shared.ParseSkinString(skinStr)
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

return Server
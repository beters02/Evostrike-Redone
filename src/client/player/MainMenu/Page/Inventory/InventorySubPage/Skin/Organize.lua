export type OrderDirection = "Ascending" | "Descending"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Tables = require(Framework.Module.lib.fc_tables)
local Skins = require(ReplicatedStorage.Assets.Shop.Skins)

local Organize = {}
local Config = require(script.Parent.Config)
local Frames = require(script.Parent:WaitForChild("Frames"))


function Organize.ByRarity(self, orderDirection: OrderDirection)
    local orderArr = Config.ConvertOrderToArray()

    local inventory = PlayerData:Get().ownedItems
    local invSkinItems = Tables.clone(inventory.skin)
    local new = {case = inventory.case, key = inventory.key, equipped = inventory.equipped, skin = {}}

    for _, rarity in pairs(orderArr) do
        for i, v in pairs(invSkinItems) do
            local skinRarity = Skins.GetSkinRarityFromInvString(v)
            if string.lower(skinRarity) == rarity then
                table.insert(new.skin, v)
                invSkinItems[i] = nil
            end
        end
    end

    Frames.UpdateSkinFrames(self, new)
end

function Organize.ByDateAdded(self)
    Frames.UpdateSkinFrames(self)
end

return Organize
export type ItemDescription = {
    ItemName: string,
    UUID: string?,
    Rarity: string?
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.shfc_strings.Location)
local ShopRarity = require(ReplicatedStorage.Assets.Shop.Rarity)

local ItemDisplay = {
    IsActive = false,
    Frame = false :: Frame?,
    Connections = {}
}

-- Initialize the ItemPage for MainMenu where MainMenu is self
function ItemDisplay.init(self, frame)
    ItemDisplay.Frame = frame
    self.ItemDisplay = ItemDisplay
end

function ItemDisplay.Open(self, description: ItemDescription, connectionCallback)
    if ItemDisplay.IsActive then
        return
    end

    ItemDisplay.IsActive = true

    ItemDisplay.Frame.ItemName.Text = description.ItemName
    ItemDisplay.Frame.IDLabel.Visible = description.UUID and true or false
    ItemDisplay.Frame.IDLabel.Text = tostring(description.UUID)

    ItemDisplay.Frame.RarityLabel.Visible = description.Rarity and true or false
    ItemDisplay.Frame.RarityLabel.Text = tostring(description.Rarity)
    if description.Rarity and description.Rarity ~= "Default" then
        self.itemDisplayFrame.RarityLabel.TextColor3 = ShopRarity[description.Rarity].color
    end

    ItemDisplay.Disconnect()
    connectionCallback(ItemDisplay)

    self.LastOpenPage = self.Location.Case.Visible and self.Location.Case or self.Location.Skin
    self.Location.Case.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.Visible = false
    self.Location.SkinsButton.Visible = false
    self.Location.KeysButton.Visible = false
    self.Location.NextPageNumberButton.Visible = false
    self.Location.PreviousPageNumberButton.Visible = false
    self.Location.CurrentPageNumberLabel.Visible = false
    ItemDisplay.Frame.Visible = true
end

function ItemDisplay.Disconnect()
    local function loop(tab)
        for _, v in pairs(tab) do
            if type(v) == "table" then
                loop(v)
            else
                v:Disconnect()
            end
        end
    end
    loop(ItemDisplay.Connections)
    ItemDisplay.Connections = {}
end

return ItemDisplay
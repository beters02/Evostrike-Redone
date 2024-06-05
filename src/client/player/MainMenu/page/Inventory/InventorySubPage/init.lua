-- [[ InventorySubPage Class ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

local ItemDisplay = {}
ItemDisplay.__index = ItemDisplay

function ItemDisplay.new(SubPage)
    local self = setmetatable({}, ItemDisplay)
    self.SubPage = SubPage

    self.Frame = SubPage.Inventory.Frame.ItemDisplayFrame:Clone()
    self.Frame.Name = SubPage.Name .. "_ItemDisplayFrame"
    self.Frame.Visible = false
    self.Frame.Parent = SubPage.Inventory.Frame

    self.Connections = {}
    self.Var = {CurrentSkinfo = false}
    return self
end

function ItemDisplay:Open()
    self.Frame.Visible = true
    self:Connect()
end

function ItemDisplay:Close()
    self.Frame.Visible = false
    self:Disconnect()
end

function ItemDisplay:Connect()
    local _c1 = self.Frame.MainButton.MouseButton1Click:Connect(function()
        self:ClickedMainButton()
    end)
    local _c2 = self.Frame.SecondaryButton.MouseButton1Click:Connect(function()
        self:ClickedSecondaryButton()
    end)
    local _c3 = self.Frame.BackButton.MouseButton1Click:Connect(function()
        self:ClickedBackButton()
    end)
    table.insert(self.Connections, _c1)
    table.insert(self.Connections, _c2)
    table.insert(self.Connections, _c3)
end

function ItemDisplay:Disconnect()
    for _, v in pairs(self.Connections) do
        v:Disconnect()
    end
end

-- Override Main Button Clicked
function ItemDisplay:ClickedMainButton() end

-- Override Sec Button Clicked
function ItemDisplay:ClickedSecondaryButton() end

-- Override Back Button Clicked
function ItemDisplay:ClickedBackButton() end

-- Override Change Item Display Item
-- @var skinfo = {model = "", skin = "", uuid = "", rarity = "", frame = Frame}
function ItemDisplay:ChangeDisplayedItem(skinfo) end

-- Inventory SubPage will be a Container Frame with 1 or more Content Frames as children.
local InventorySubPage = {}
InventorySubPage.__index = InventorySubPage

function InventorySubPage.new(Inventory, Frame, Name)
    local self = setmetatable({}, InventorySubPage)
    self.Name = Name
    self.Inventory = Inventory
    self.Frame = Frame

    self.ItemDisplay = ItemDisplay.new(self)

    self.ItemPageFrames = {}
    self.ItemPageNumberVar = {
        Connections = {},
        PageAmount = 1,
        CurrentPage = 1,
    }

    self.Connections = {}
    self.Var = {ItemDisplayOpened = false, PageChangeConnected = false}
    return self
end

function InventorySubPage:Open()
    if self.Var.ItemDisplayOpened then
        self.ItemDisplay:Open()
    end
    self:Update()
    self:Connect()
    self.Frame.Visible = true
end

function InventorySubPage:Close()
    if self.Var.ItemDisplayOpened then
        self:CloseItemDisplay(true)
    end
    self:Disconnect()
    self.Frame.Visible = false
end

function InventorySubPage:OpenItemDisplay()
    self.Var.ItemDisplayOpened = true
    self.ItemDisplay:Open()
end

function InventorySubPage:CloseItemDisplay(onPageClose)
    if not onPageClose then
        self.Var.ItemDisplayOpened = false
    end
    self.ItemDisplay:Close()
end

function InventorySubPage:Connect()
    self:ConnectPageChangeButtons()
end

function InventorySubPage:ConnectPageChangeButtons()
    if self.Var.PageChangeConnected then
        return
    end
    self.Var.PageChangeConnected = true
    self.ItemPageNumberVar.Connections.NextPage = self.Frame.NextPageNumberButton.MouseButton1Click:Connect(function()
        self:NextContentFrame()
    end)
    self.ItemPageNumberVar.Connections.PreviousPage = self.Frame.PreviousPageNumberButton.MouseButton1Click:Connect(function()
        self:PreviousContentFrame()
    end)
end

function InventorySubPage:DisconnectPageChangeButtons()
    if not self.Var.PageChangeConnected then
        return
    end
    self.Var.PageChangeConnected = false
    for _, v in pairs({"NextPage", "PreviousPage"}) do
        local conn = self.ItemPageNumberVar.Connections[v]
        if conn then
            conn:Disconnect()
        end
    end
end

function InventorySubPage:Disconnect()
    for _, v in pairs(self.Connections) do
        v:Disconnect()
    end
    self:DisconnectPageChangeButtons()
end

function InventorySubPage:AddContentFrame(num) -- Num will never be 1 since first content frame is pre-created
    local c = self.Frame.Content1:Clone()
    c.Name = "Content" .. tostring(num)
    c.Parent = self.Frame
    c.BackgroundTransparency = 0.944
    c.Visible = false
    return c
end

function InventorySubPage:NextContentFrame()
    local curr = self.ItemPageNumberVar.CurrentPage
    if curr == self.ItemPageNumberVar.PageAmount then
        return
    end

    print("Prechange current page: " .. tostring(curr))

    self.Frame["Content" .. tostring(curr)].Visible = false
    curr += 1
    self.Frame["Content" .. tostring(curr)].Visible = true
    
    self.Frame.CurrentPageNumberLabel.Text = tostring(curr)
    self.ItemPageNumberVar.CurrentPage = curr

    print("Postchange current page: " .. tostring(curr))
end

function InventorySubPage:PreviousContentFrame()
    local curr = self.ItemPageNumberVar.CurrentPage
    if curr == 1 then
        return
    end
    self.Frame["Content" .. tostring(curr)].Visible = false

    curr -= 1
    self.Frame["Content" .. tostring(curr)].Visible = true
    self.Frame.CurrentPageNumberLabel.Text = tostring(curr)
    self.ItemPageNumberVar.CurrentPage = curr
end

function InventorySubPage:Update() end

return InventorySubPage
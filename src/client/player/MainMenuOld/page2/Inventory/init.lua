local Page = require(script.Parent)

-- SubPages are the Contanier Frames which have their own Content Frames (SkinPage, CasePage, KeyPage)
local SubPage = require(script.InventorySubPage)

local Inventory = {}

function Inventory:init(frame)
    Inventory = setmetatable(Page.new(frame), Inventory)
    Inventory.Var = {CurrentOpenSubPage = false}
    Inventory.Connections = {}
    Inventory.SubPages = {}
    Inventory.SubPages.Skin = SubPage:init(Inventory, "Skin")
end

function Inventory:Open()
    self:_open()

    if self.Var.CurrentOpenSubPage then
        self.Var.CurrentOpenSubPage:Open()
    end
end

function Inventory:Close()
    self:_close()

    if self.Var.CurrentOpenSubPage then
        self.Var.CurrentOpenSubPage:Close()
    end
end

function Inventory:OpenSubPage(name)
    local subpage = Inventory.SubPages[name]
    if not subpage then
        return
    end

    if Inventory.Var.CurrentOpenSubPage then
        self:CloseSubPage(Inventory.Var.CurrentOpenSubPage.Name)
    end
    
    Inventory.Var.CurrentOpenSubPage = subpage
    connectChangeContentFrameButtons(self)
end

function Inventory:CloseSubPage(name, onPageClose)
    local subpage = Inventory.SubPages[name]
    if not subpage then
        return
    end

    disconnectChangeContentFrameButtons(self)
    subpage:Close()
end

function connectChangeContentFrameButtons(self)
    disconnectChangeContentFrameButtons(self)
    self.Connections.NextPageNum = self.Frame.NextPageNumberButton.MouseButton1Click:Connect(function()
        self.Var.CurrentOpenSubPage:NextContentFrame()
    end)
    self.Connections.PrevPageNum = self.Frame.PreviousPageNumberButton.MouseButton1Click:Connect(function()
        self.Var.CurrentOpenSubPage:PreviousContentFrame()
    end)
end

function disconnectChangeContentFrameButtons(self)
    if self.Connections.NextPageNum then
        self.Connections.NextPageNum:Disconnect()
    end
    if self.Connections.PrevPageNum then
        self.Connections.PrevPageNum:Disconnect()
    end
end

return Inventory
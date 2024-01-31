

-- SubPages are the Contanier Frames which have their own Content Frames (SkinPage, CasePage, KeyPage)
local SubPage = require(script.InventorySubPage)
local SkinSubPage = require(script.InventorySubPage.Skin)

local Page = require(script.Parent)
local Inventory = setmetatable({}, Page)
Inventory.__index = Inventory

function Inventory.new(mainMenu, frame)
    local self = setmetatable(Page.new(mainMenu, frame), Inventory)
    self.Frame = frame
    self.Var = {CurrentOpenSubPage = false}
    self.Connections = {}
    self.SubPages = {}
    self.SubPages.Skin = SkinSubPage:init(self, frame.Skin)
    self.Var.CurrentOpenSubPage = self.SubPages.Skin
    --self.SubPages.Skin = SubPage.new(Inventory, )
    --self.SubPages.Skin = SubPage:init(Inventory, "Skin")
    return self
end

function Inventory:init(frame)
    self._init()
end

function Inventory:Open()
    self._Open()
    if self.Var.CurrentOpenSubPage then
        self.Var.CurrentOpenSubPage:Open()
    end
end

function Inventory:Close()
    self._Close()
    if self.Var.CurrentOpenSubPage then
        self.Var.CurrentOpenSubPage:Close()
    end
end

function Inventory:Update()
    self.SubPages.Skin:Update()
end

function Inventory:OpenSubPage(name)
    local subpage = self.SubPages[name]
    if not subpage then
        return
    end

    if Inventory.Var.CurrentOpenSubPage then
        self:CloseSubPage(self.Var.CurrentOpenSubPage.Name)
    end
    
    self.Var.CurrentOpenSubPage = subpage
    connectChangeContentFrameButtons(self)
end

function Inventory:CloseSubPage(name, onPageClose)
    local subpage = self.SubPages[name]
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
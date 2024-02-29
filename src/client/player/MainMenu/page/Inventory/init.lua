

-- SubPages are the Contanier Frames which have their own Content Frames (SkinPage, CasePage, KeyPage)
local SubPage = require(script.InventorySubPage)
local SkinSubPage = require(script.InventorySubPage.Skin)
local CaseSubPage = require(script.InventorySubPage.Case)
local KeySubPage = require(script.InventorySubPage.Key)

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
    self.SubPages.Case = CaseSubPage:init(self, frame.Case)
    self.SubPages.Key = KeySubPage:init(self, frame.Key)
    self.Var.CurrentOpenSubPage = self.SubPages.Skin

    self.SubPageButtons = {
        Skin = frame.SkinsButton,
        Key = frame.KeysButton,
        Case = frame.CasesButton
    }
    return self
end

function Inventory:init(frame)
    self._init()
end

function Inventory:Open()
    self._Open()
    connectSubPageButtons(self)
    if self.Var.CurrentOpenSubPage then
        self.Var.CurrentOpenSubPage:Open()
    end
end

function Inventory:Close()
    self._Close()
    disconnectSubPageButtons(self)
    if self.Var.CurrentOpenSubPage then
        self.Var.CurrentOpenSubPage:Close()
    end
end

function Inventory:Update()
    self.SubPages.Skin:Update()
    self.SubPages.Case:Update()
end

function Inventory:OpenSubPage(name)
    local subpage = self.SubPages[name]
    if not subpage then
        return
    end

    if self.Var.CurrentOpenSubPage then
        self:CloseSubPage(self.Var.CurrentOpenSubPage.Name)
    end

    subpage:Open()
    self.Var.CurrentOpenSubPage = subpage
    self.SubPageButtons[name].BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

function Inventory:CloseSubPage(name)
    local subpage = self.SubPages[name]
    if not subpage then
        return
    end

    subpage:Close()
    self.SubPageButtons[name].BackgroundColor3 = Color3.fromRGB(80, 96, 118)
end

function Inventory:EnableSubPageButtons()
    disconnectSubPageButtons(self)
    connectSubPageButtons(self)
    for _, v in pairs({"Skin", "Case", "Key"}) do
        self.Frame[v.."sButton"].Visible = true
    end
end

function Inventory:DisableSubPageButtons()
    disconnectSubPageButtons(self)
    for _, v in pairs({"Skin", "Case", "Key"}) do
        self.Frame[v.."sButton"].Visible = false
    end
end

function connectSubPageButtons(self)
    for _, v in pairs({"Skin", "Case", "Key"}) do
        self.Connections["Open"..v.."SubPage"] = self.Frame[v.."sButton"].MouseButton1Click:Connect(function()
            if self.Var.CurrentOpenSubPage == self.SubPages[v] then
                return
            end
            self:OpenSubPage(v)
        end)
    end
end

function disconnectSubPageButtons(self)
    for _, v in pairs({"Skin", "Case", "Key"}) do
        if self.Connections["Open"..v.."SubPage"] then
            self.Connections["Open"..v.."SubPage"]:Disconnect()
        end
    end
end

return Inventory
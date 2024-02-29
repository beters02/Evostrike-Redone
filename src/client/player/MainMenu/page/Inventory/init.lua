--[[
    When creating a new knife, make sure to init in the init function
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

<<<<<<< Updated upstream
local inventory = {}
local skinPage = require(script:WaitForChild("SkinPage"))
local casePage = require(script:WaitForChild("CasePage"))
local keyPage = require(script:WaitForChild("KeyPage"))
inventory.skinPage = skinPage
inventory.casePage = casePage
inventory.keyPage = keyPage
=======
-- SubPages are the Contanier Frames which have their own Content Frames (SkinPage, CasePage, KeyPage)
local SubPage = require(script.InventorySubPage)
local SkinSubPage = require(script.InventorySubPage.Skin)
local CaseSubPage = require(script.InventorySubPage.Case)
local KeySubPage = require(script.InventorySubPage.Key)
>>>>>>> Stashed changes

function inventory:init()
    self.mainButtonConnections = {}
    self.currentPageButtonConnections = {}
    self.currentOpenPage = skinPage

<<<<<<< Updated upstream
    skinPage.init(self, self.Location.Skin)
    casePage.init(self, self.Location.Case)
    keyPage.init(self, self.Location.Key)
    self:Update()
=======
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
>>>>>>> Stashed changes
    return self
end

function inventory:Open()
    self.Location.Visible = true
    self:ConnectMainButtons()
    self:OpenAnimations()
    self:Update()
    self:OpenItemPage(self.currentOpenPage)
end

function inventory:Close()
    self.Location.Visible = false
    self:DisconnectMainButtons()
    self:CloseCurrentItemPage()
    skinPage.CloseItemDisplay(self)
    casePage.CloseItemDisplay(self)
end

function inventory:Update()
    self:Clear()

    local playerInventory = PlayerData:UpdateFromServer(true).ownedItems
    skinPage.Update(self, playerInventory)
    casePage.Update(self, playerInventory)
    keyPage.Update(self, playerInventory)
end

function inventory:Clear()
    skinPage.Clear(self)
    casePage.Clear(self)
    keyPage.Clear(self)
end

function inventory:OpenItemPage(page, button)
    if (button and not button.Visible) then
        return
    end
    self:PlaySound("Open")
    self:CloseCurrentItemPage()
    page.Open(self)
    self.currentOpenPage = page
end

function inventory:CloseCurrentItemPage()
    for _, v in pairs(self.currentPageButtonConnections) do
        v:Disconnect()
    end
    self.currentPageButtonConnections = {}
    self.currentOpenPage.MainFrame.Visible = false
end

function inventory:ConnectMainButtons()
    local conn = {}
    local bSkin = self.Location.SkinsButton
    local bCase = self.Location.CasesButton
    local bKey = self.Location.KeysButton
    conn.openskin = bSkin.MouseButton1Click:Connect(function()
        self:OpenItemPage(skinPage, bSkin)
    end)
    conn.opencase = bCase.MouseButton1Click:Connect(function()
        self:OpenItemPage(casePage, bCase)
    end)
    conn.openkey = bKey.MouseButton1Click:Connect(function()
        self:OpenItemPage(keyPage, bKey)
    end)
    conn.changed = PlayerData:PathValueChanged("ownedItems.skin", function()
        self:Update()
    end)
    self.mainButtonConnections = conn
end

function inventory:DisconnectMainButtons()
    for _, v in pairs(self.mainButtonConnections) do
        v:Disconnect()
    end
    self.mainButtonConnections = {}
end

<<<<<<< Updated upstream
return inventory
=======
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
>>>>>>> Stashed changes

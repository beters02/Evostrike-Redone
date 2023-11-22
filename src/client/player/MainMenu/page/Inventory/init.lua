--[[
    When creating a new knife, make sure to init in the init function
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Cases = game.ReplicatedStorage.Assets.Cases

local inventory = {}
local skinPage = require(script:WaitForChild("SkinPage"))
local casePage = require(script:WaitForChild("CasePage"))
inventory.skinPage = skinPage
inventory.casePage = casePage

function inventory:init()
    self.itemDisplayFrame = self.Location:WaitForChild("ItemDisplayFrame")
    self.itemDisplayVar = {active = false, caseOpeningActive = false}
    self.itemDisplayConns = {}
    skinPage.init(self)
    self:Update()
    return self
end

function inventory:Open()
    self.Location.Visible = true
    self:ConnectButtons()
    self:OpenAnimations()
end

function inventory:Close()
    self.Location.Visible = false
    self:DisconnectButtons()
end

function inventory:Update(withClear: boolean?)
    print('Update Recieved!')
    if withClear then
        self:Clear()
    end

    local playerdata = PlayerData:UpdateFromServer(true)
    self._currentStoredInventory = playerdata.inventory.skin
    self._currentEquippedInventory = playerdata.inventory.equipped
    self._currentStoredCaseInventory = playerdata.inventory.case
    self._currentStoredKeyInventory = playerdata.inventory.key

    task.spawn(function()
        skinPage.Update(self)
    end)

    -- initialize player's case inventory
    for _, v: string in pairs(self._currentStoredCaseInventory) do
        self:CreateCaseFrame(v:gsub("case_", ""))
    end

    -- init player's key inventory
    for _, v: string in pairs(self._currentStoredKeyInventory) do
        self:CreateKeyFrame(v:gsub("key_", ""))
    end
end

function inventory:Clear()
    for _, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "ItemFrame" then
            v:Destroy()
        end
    end
    for _, v in pairs(self.Location.Case.Content:GetChildren()) do
        if v:IsA("Frame") and v.Name ~= "ItemFrame" then
            v:Destroy()
        end
    end
end

--
function inventory:ConnectButtons()
    self._bconnections = {}
    self._bconnections.openskin = self.Location.SkinsButton.MouseButton1Click:Connect(function()
        if self.Location.Skin.Visible or not self.Location.SkinsButton.Visible then
            return
        end
        self:OpenSkinPage()
    end)
    self._bconnections.opencase = self.Location.CasesButton.MouseButton1Click:Connect(function()
        if self.Location.Case.Visible or not self.Location.CasesButton.Visible then
            return
        end
        self:OpenCasePage()
    end)
    self._bconnections.openkey = self.Location.KeysButton.MouseButton1Click:Connect(function()
        if self.Location.Key.Visible or not self.Location.KeysButton.Visible then
            return
        end
        self:OpenKeyPage()
    end)

    skinPage.ConnectButtons(self)
    casePage.ConnectButtons(self)
end

function inventory:DisconnectButtons()
    for _, v in pairs(self._bconnections) do
        v:Disconnect()
    end
    self._bconnections = {}
end

-- [[ SKIN PAGE ]]
function inventory:OpenSkinPage()
    self.Location.Case.Visible = false
    self.Location.Key.Visible = false
    self.Location.Skin.Visible = true
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

-- [[ CASE PAGE ]]
function inventory:OpenCasePage()
    self.Location.Case.Visible = true
    self.Location.Key.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

-- [[ ITEM DISPLAY ]]
function inventory:OpenItemDisplay(caseFrame)
    if self.itemDisplayVar.active then return end
    self.itemDisplayVar.active = true -- turned off in CloseItemDisplay()

    self.itemDisplayFrame.CaseDisplay.Visible = true
    self.itemDisplayFrame.ItemDisplayImageLabel.Visible = false
    local itemDisplayName = caseFrame:GetAttribute("ItemDisplayName") or caseFrame.Name
    self.itemDisplayFrame.ItemName.Text = string.upper(itemDisplayName)
    self.itemDisplayFrame.MainButton.Text = "OPEN"

    self.itemDisplayConns.MainButton = self.itemDisplayFrame.MainButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.caseOpeningActive then
            return
        end
        self.itemDisplayVar.caseOpeningActive = true
        self:OpenCaseButtonClicked(caseFrame)
        self.itemDisplayVar.caseOpeningActive = false
    end)

    self.itemDisplayConns.BackButton = self.itemDisplayFrame.BackButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.caseOpeningActive then
            return
        end
        self:CloseItemDisplay()
    end)

    self.LastOpenPage = self.Location.Case.Visible and self.Location.Case or self.Location.Skin
    self.Location.Case.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.Visible = false
    self.Location.SkinsButton.Visible = false
    self.itemDisplayFrame.Visible = true
end

function inventory:CloseItemDisplay()
    self.itemDisplayVar.active = false
    self.itemDisplayConns.MainButton:Disconnect()
    self.itemDisplayConns.BackButton:Disconnect()
    self.itemDisplayFrame.Visible = false
    self.LastOpenPage.Visible = true
end

-- [[ KEY PAGE ]]
function inventory:OpenKeyPage()
    self.Location.Case.Visible = false
    self.Location.Key.Visible = true
    self.Location.Skin.Visible = false
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

function inventory:CreateKeyFrame(case: string)
    local caseFolder = Cases:FindFirstChild(string.lower(case))
    if not caseFolder then
        warn("Could not find CaseFolder for case " .. tostring(case))
        return
    end

    local itemFrame = self.Location.Key.Content.ItemFrame:Clone()
    local itemModel = caseFolder.DisplayFrame.Model:Clone()
    itemModel.Parent = itemFrame:WaitForChild("ViewportFrame")
    itemModel:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 0, -5)))

    itemFrame.Name = "SkinFrame_" .. string.lower(case)
    itemFrame:WaitForChild("NameLabel").Text = caseFolder:GetAttribute("DisplayName") or case
    itemFrame.NameLabel.Text = string.upper(itemFrame.NameLabel.Text) .. " KEY"
    itemFrame.Visible = true
    itemFrame.Parent = self.Location.Key.Content
    itemFrame:SetAttribute("CaseName", string.lower(case))
    return itemFrame
end

return inventory
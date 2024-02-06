local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local CaseAssets = ReplicatedStorage.Assets.Cases
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local ShopInterface = require(Framework.Module.ShopInterface)
local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local PlayerData = require(Framework.Module.PlayerData)
local AttemptItemSellGui = ShopAssets:WaitForChild("AttemptItemSell")

local Popup = require(script.Parent.Parent.Parent.Parent.Popup)
local AttemptOpenCaseGui = ShopAssets:WaitForChild("AttemptOpenCase")

local Config = require(script:WaitForChild("Config"))
local OpenSequence = require(script:WaitForChild("OpenSequence"))
local InventorySubPage = require(script.Parent)
local Case = setmetatable({}, InventorySubPage)
Case.__index = Case

function Case:init(Inventory, frame)
    Case = setmetatable(InventorySubPage.new(Inventory, frame, "Case"), Case)
    Case.CasePageFrames = {}
    Case.CasePageConnections = {}

    Case.ItemDisplay.Frame.MainButton.Text = "OPEN"
    Case.ItemDisplay.Frame.SecondaryButton.Text = "SELL"
    Case.ItemDisplay.Frame.SecondaryButton.Visible = true
    Case.ItemDisplay.Frame.IDLabel.Visible = false
    Case.ItemDisplay.Frame.RarityLabel.Visible = false
    Case.ItemDisplay.Frame.ItemDisplayImageLabel.Visible = false
    Case.ItemDisplay.Frame.CaseDisplay.Visible = true

    -- "OPEN"
    Case.ItemDisplay.ClickedMainButton = function()
        if Case.ActionProcessing then return end
        Case.ActionProcessing = true

        Case.Inventory.Main:PlayButtonSound("Select1")
        caseOpenButtonClicked(Case)
        
        Case.ActionProcessing = false
    end

    -- "SELL"
    Case.ItemDisplay.ClickedSecondaryButton = function(itd)
        if Case.ActionProcessing then return end
        Case.ActionProcessing = true

        Case.Inventory.Main:PlayButtonSound("Select1")
        sellCase(Case, Case.CurrentCaseName)

        Case.ActionProcessing = false
    end

    -- "BACK"
    Case.ItemDisplay.ClickedBackButton = function(itd)
        Case.Inventory.Main:PlayButtonSound("Select1")
        Case.Frame.Visible = true
        Case:CloseItemDisplay()
        Case.Inventory:EnableSubPageButtons()
    end

    Case.ItemDisplay.ChangeDisplayedItem = changeDisplayItem

    return Case
end

function Case:Open()
    InventorySubPage.Open(self)
    connectCaseFrames(self)
end

function Case:Close()
    InventorySubPage.Close(self)
    disconnectCaseFrames(self)
end

function Case:Update()
    InventorySubPage.Update(self)
    updateCaseFrames(self)
end

function Case._createCaseModel(case)
    local caseFolder = getCaseFolder(case)
    local itemModel = caseFolder.DisplayFrame.Model:Clone()
    itemModel:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 0, -5)))
    return itemModel
end

function getCaseFolder(case)
    local caseFolder = CaseAssets:FindFirstChild(string.lower(case))
    if not caseFolder then
        warn("Could not find CaseFolder for case " .. tostring(case))
        return false
    end
    return caseFolder
end

function changeDisplayItem(itd, case)
    local caseFolder = getCaseFolder(case)
    Case.ItemDisplay.Frame.ItemName.Text = caseFolder:GetAttribute("DisplayName") or case
    Case.ItemDisplay.Frame.IDLabel.Visible = false
    Case.ItemDisplay.Frame.ItemDisplayImageLabel.Visible = false
    Case.ItemDisplay.Frame.CaseDisplay.Visible = true
    Case.ItemDisplay.Frame.CaseDisplay.ViewportFrame:ClearAllChildren()

    local model = Case._createCaseModel(case)
    model.Parent = Case.ItemDisplay.Frame.CaseDisplay.ViewportFrame
    model:SetPrimaryPartCFrame(model.PrimaryPart.CFrame + Vector3.new(0,0,7.8))

    Case.CurrentCaseName = Case.ItemDisplay.Frame.ItemName.Text
end

--

function createCaseFrame(self, case: string, pageIndex: number)
    self.ItemDisplay.Frame.CaseDisplay.ViewportFrame:ClearAllChildren()

    -- for now we just use the only case that we have
    local model = ReplicatedStorage.Assets.Cases.weaponcase1.Model:Clone()
    model.Parent = self.ItemDisplay.Frame.CaseDisplay.ViewportFrame

    local caseFolder = getCaseFolder(case)

    local itemFrame = self.Frame.Content1.ItemFrame:Clone()
    local itemModel = Case._createCaseModel(case)
    itemModel.Parent = itemFrame:WaitForChild("ViewportFrame")
    
    itemFrame.Name = "SkinFrame_" .. string.lower(case)
    itemFrame:WaitForChild("NameLabel").Text = caseFolder:GetAttribute("DisplayName") or case
    itemFrame.NameLabel.Text = string.upper(itemFrame.NameLabel.Text)
    itemFrame.Visible = true
    itemFrame.Parent = self.Frame["Content" .. tostring(pageIndex)]
    itemFrame:SetAttribute("CaseName", string.lower(case))
    return itemFrame
end

function updateCaseFrames(self)

    local playerInventory = PlayerData:Get().ownedItems.case
    local frames = {[1] = {}} -- index per page number (pagesAmount)
    local pagesAmount = 0
    local pageIndex = 1

    destroyCurrentCaseFrames(self)

    pagesAmount = getNeededPagesAmount(#playerInventory)
    self.ItemPageNumberVar.PageAmount = pagesAmount

    if pagesAmount > 1 then
        self:ConnectPageChangeButtons()
        for i = 2, pagesAmount+1 do
            self:AddContentFrame(i)
            frames[i] = {}
        end
    end

    for _, unsplit in pairs(playerInventory) do
        if #frames[pageIndex] >= Config.MaxFramesPerPage then
            pageIndex += 1
        end

        local case = string.gsub(unsplit, "case_", "")
        local frame = createCaseFrame(self, case, pageIndex)
        frame:SetAttribute("Case", case)
        table.insert(frames[pageIndex], frame)
    end

    self.CasePageFrames = frames
end

function destroyCurrentCaseFrames(self)
    for i, v in pairs(self.CasePageFrames) do
        for k, a in pairs(v) do
            a:Destroy()
            self.CasePageFrames[i][k] = nil
        end
    end
end

function getNeededPagesAmount(frameAmnt)
    return math.ceil(frameAmnt/Config.MaxFramesPerPage)
end

--

function caseFrameClicked(self, frame)
    local case = frame:GetAttribute("Case")
    self.ItemDisplay:ChangeDisplayedItem(case)
    self:OpenItemDisplay()
    self.CurrentOpenSkinFrame = frame
    self.Frame.Visible = false
    self.Inventory:DisableSubPageButtons()
end

function connectCaseFrames(self)
    for _, p in pairs(self.CasePageFrames) do
        for _, v in pairs(p) do
            table.insert(self.CasePageConnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
                if not self.Frame.Visible then
                    return
                end
                caseFrameClicked(self, v)
            end))
        end
    end
end

function disconnectCaseFrames(self)
    for i, v in pairs(self.CasePageConnections) do
        v:Disconnect()
        self.CasePageConnections[i] = nil
    end
end

--

function caseOpenButtonClicked(self)
    self.Inventory.Main:PlayButtonSound("Open")
    local caseName = self.CurrentCaseName

    -- Confirm Case Open/Key Purchase
    local hasKey = ShopInterface:HasKey(convertCaseStr(caseName))
    local hasConfirmed = false
    local confirmGui = AttemptOpenCaseGui:Clone()
    local keyAcceptButton = confirmGui:WaitForChild("Frame"):WaitForChild("KeyAcceptButton")
    local declineButton = confirmGui.Frame:WaitForChild("DeclineButton")
    CollectionService:AddTag(confirmGui, "CloseItemDisplay")
    
    if hasKey then
        keyAcceptButton.Text = "use key"
        confirmGui.Frame.KeyNotOwnedLabel.Visible = false
    else
        keyAcceptButton.Text = "purchase key"
        confirmGui.Frame.KeyNotOwnedLabel.Visible = true
    end

    self.Connections.CaseConfirmation = keyAcceptButton.MouseButton1Click:Connect(function()
        if hasConfirmed then return end
        hasConfirmed = true
        if hasKey then
            attemptOpenCase(self, caseName)
        else
            self.Inventory.Main:OpenPage("Shop")
        end
        confirmGui:Destroy()
        self.Connections.DeclineButton:Disconnect()
        self.Connections.CaseConfirmation:Disconnect()
    end)

    self.Connections.DeclineButton = declineButton.MouseButton1Click:Connect(function()
        if hasConfirmed then return end
        confirmGui:Destroy()
        self.Connections.CaseConfirmation:Disconnect()
        self.Connections.DeclineButton:Disconnect()
    end)

    confirmGui.Parent = game.Players.LocalPlayer.PlayerGui
    self.CaseOpeningActive = false
end

function attemptOpenCase(self, caseName)
    caseName = convertCaseStr(caseName)

    local openedSkin, potentialSkins
    local success, result = pcall(function()
        openedSkin, potentialSkins = ShopInterface:OpenCase(caseName)
    end)

    if success then
        self.Inventory.Main:PlayButtonSound("Purchase1")
        task.spawn(function()
            openCase(self, openedSkin, potentialSkins)
        end)
    else
        self.Inventory.Main:PlayButtonSound("Error1")
        Popup.new(tostring(result), 3)
    end
end

function openCase(self, openedSkin, potentialSkins)
    OpenSequence(self, openedSkin, potentialSkins)
end

function convertCaseStr(str: string)
    return str:gsub(" ", ""):lower()
end

function sellCase(self, case)
    if self.ItemDisplay.Var.IsSelling then
        return
    end
    self.ItemDisplay.Var.IsSelling = true

    local caseName = convertCaseStr(case)
    local shopItemStr = "case_" .. caseName
    local shopItem = ShopInterface:GetItemPrice(shopItemStr)

    local confirmgui = AttemptItemSellGui:Clone()
    local mainframe = confirmgui:WaitForChild("Frame")
    confirmgui.Parent = game.Players.LocalPlayer.PlayerGui

    mainframe:WaitForChild("CaseLabel").Visible = true
    mainframe:WaitForChild("WeaponLabel").Visible = false
    mainframe:WaitForChild("SkinLabel").Visible = false

    mainframe.CaseLabel.Text = string.upper(caseName)
    mainframe.SCAcceptButton.Text = tostring(shopItem.sell_sc) .. " SC"

    local conns = {}
    conns[1] = mainframe.SCAcceptButton.MouseButton1Click:Once(function()
        conns[2]:Disconnect()
        local succ = ShopInterface:SellItem(shopItemStr, caseName)
        if succ then
            Popup.new(game.Players.LocalPlayer, "Successfully sold item for " .. tostring(shopItem.sell_sc) .. " SC!", 3)
            self:CloseItemDisplay()
            --CasePage.ConnectButtons(self)
        else
            Popup.new(game.Players.LocalPlayer, "Could not sell item.", 3)
        end
        self.ItemDisplay.Var.IsSelling = false
        confirmgui:Destroy()
        conns[1]:Disconnect()
    end)

    conns[2] = mainframe.DeclineButton.MouseButton1Click:Once(function()
        conns[1]:Disconnect()
        confirmgui:Destroy()
        self.ItemDisplay.Var.IsSelling = false
        conns[2]:Disconnect()
    end)

    confirmgui.Enabled = true
end

return Case
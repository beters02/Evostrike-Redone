local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local InventoryInterface = require(Framework.Module.InventoryInterface.Shared)
local ShopInterface = require(Framework.Module.ShopInterface)
local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local Strings = require(Framework.Module.lib.fc_strings)

local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local Cases = game.ReplicatedStorage.Assets.Cases
local AttemptOpenCaseGui = ShopAssets:WaitForChild("AttemptOpenCase")
local AttemptItemSellGui = ShopAssets:WaitForChild("AttemptItemSell")

local CasePage = {}

function CasePage:init(frame)
    CasePage.MainFrame = frame
    self.CasePageFrames = {}
    self.itemDisplayFrame = self.Location:WaitForChild("ItemDisplayFrame")
    self.itemDisplayVar = {active = false, caseOpeningActive = false}
    self.itemDisplayConns = {}
end

function CasePage:Open()
    self.Location.Case.Visible = true
    self.Location.Key.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    CasePage.ConnectButtons(self)
end

function CasePage:Clear()
    for _, v in pairs(self.CasePageFrames) do
        v:Destroy()
    end
    self.CasePageFrames = {}
end

function CasePage:Update(playerInventory)
    CasePage.Clear(self)
    for i, case in pairs(playerInventory.case) do
        self.CasePageFrames[i] = CasePage.CreateCaseFrame(self, case)
    end
end

function CasePage:ConnectButtons()
    for _, v in pairs(self.Location.Case.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        table.insert(self.currentPageButtonConnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
            if not self.Location.Case.Visible then return end
            CasePage.CaseButtonClicked(self, v)
        end))
    end
end

function CasePage:CreateCaseFrame(case: string)
    local caseFolder = Cases:FindFirstChild(string.lower(case))
    if not caseFolder then
        warn("Could not find CaseFolder for case " .. tostring(case))
        return
    end

    local itemFrame = self.Location.Case.Content.ItemFrame:Clone()
    local itemModel = caseFolder.DisplayFrame.Model:Clone()
    itemModel.Parent = itemFrame:WaitForChild("ViewportFrame")
    itemModel:SetPrimaryPartCFrame(CFrame.new(Vector3.new(0, 0, -5)))

    itemFrame.Name = "SkinFrame_" .. string.lower(case)
    itemFrame:WaitForChild("NameLabel").Text = caseFolder:GetAttribute("DisplayName") or case
    itemFrame.NameLabel.Text = string.upper(itemFrame.NameLabel.Text)
    itemFrame.Visible = true
    itemFrame.Parent = self.Location.Case.Content
    itemFrame:SetAttribute("CaseName", string.lower(case))
    return itemFrame
end

function CasePage:CaseButtonClicked(caseFrame)
    CasePage.OpenItemDisplay(self, caseFrame)
end

function CasePage:OpenCaseButtonClicked(caseFrame)
    local caseName = caseFrame:GetAttribute("CaseName")

    -- Confirm Case Open/Key Purchase
    local hasKey = ShopInterface:HasKey(caseName)
    local hasConfirmed = false
    local confirmGui = AttemptOpenCaseGui:Clone()
    local keyAcceptButton = confirmGui:WaitForChild("Frame"):WaitForChild("KeyAcceptButton")
    CollectionService:AddTag(confirmGui, "CloseItemDisplay")
    
    if hasKey then
        keyAcceptButton.Text = "use key"
        confirmGui.Frame.KeyNotOwnedLabel.Visible = false
    else
        keyAcceptButton.Text = "purchase key"
        confirmGui.Frame.KeyNotOwnedLabel.Visible = true
    end

    self.itemDisplayConns.CaseConfirmation = keyAcceptButton.MouseButton1Click:Connect(function()
        if hasConfirmed then return end
        hasConfirmed = true
        if hasKey then
            local openedSkin, potentialSkins
            local success, result = pcall(function()
                openedSkin, potentialSkins = ShopInterface:OpenCase(caseName)
            end)
            if success then
                task.spawn(function()
                    CasePage.OpenCase(self, openedSkin, potentialSkins)
                end)
            else
                Popup.burst(tostring(result), 3)
            end
        else
            self._mainPageModule:OpenPage("Shop")
        end
        confirmGui:Destroy()
        self.itemDisplayConns.CaseConfirmation:Disconnect()
    end)

    confirmGui.Parent = game.Players.LocalPlayer.PlayerGui
    self.itemDisplayVar.caseOpeningActive = false
end

function CasePage:OpenCase(gotSkin, potentialSkins)
    self.itemDisplayVar.caseOpeningActive = true
    CasePage.CloseItemDisplay(self)

    -- Prepare Var & Tween
    local seq = self.Location.CaseOpeningSequence
    local seqItem = seq.ItemDisplay
    local seqCase = seq.CaseDisplay
    local seqWheel = seq.ItemWheelDisplay
    local crates = seq.CaseDisplay.ViewportFrame.Crates
    local endCF = crates.PrimaryPart.CFrame - Vector3.new(0, 0, 1)
    local GrowTween = TweenService:Create(crates.PrimaryPart, TweenInfo.new(1), {CFrame = endCF})
    local WheelTween = TweenService:Create(seqWheel.Wheel, TweenInfo.new(3, Enum.EasingStyle.Quad), {CanvasPosition = Vector2.new(2150, 0)})

    if not self.itemDisplayVar.initCaseOpen then
        self.itemDisplayVar.initCaseOpen = true
        self.itemDisplayVar.cratesPos = crates.PrimaryPart.CFrame
    end

    crates:SetPrimaryPartCFrame(self.itemDisplayVar.cratesPos)
    seqWheel.Wheel.CanvasPosition = Vector2.new(0,0)

    -- Fill Wheel CaseFrames with Model
    local gotParsed = InventoryInterface.ParseSkinString(gotSkin)
    CasePage.FillCaseFrame(self, 1, gotParsed)
    local count = 1
    for _, v in pairs(potentialSkins) do
        count += 1
        CasePage.FillCaseFrame(self, count, InventoryInterface.ParseSkinString(v))
    end

    -- Fill ItemDisplay with Got Item
    seqItem.ItemName.Text =  Strings.firstToUpper(gotParsed.model) .. " | " .. Strings.firstToUpper(gotParsed.skin)
    local itemDisplayModel = InventoryInterface.GetSkinModelFromSkinObject(gotParsed):Clone()
    itemDisplayModel.PrimaryPart = itemDisplayModel:WaitForChild("GunComponents"):WaitForChild("WeaponHandle")
    seqItem.Display.ViewportFrame:ClearAllChildren()
    itemDisplayModel:SetPrimaryPartCFrame(CFrame.new(Vector3.zero))
    itemDisplayModel.Parent = seqItem.Display.ViewportFrame

    -- Case Opening Sequence
    self.Location.Case.Visible = false
    self.Location.Key.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.Visible = false
    self.Location.KeysButton.Visible = false
    self.Location.SkinsButton.Visible = false
    seq.Visible = true

    -- Play Grow Tween
    seqCase.Visible = true
    seqWheel.Visible = false
    seqItem.Visible = false
    GrowTween:Play()
    GrowTween.Completed:Wait()
    
    -- Play Wheel Tween
    seqCase.Visible = false
    seqWheel.Visible = true
    WheelTween:Play()
    WheelTween.Completed:Wait()

    -- play Received Item Screen
    seqWheel.Visible = false
    seqItem.Visible = true

    seqItem.BackButton.MouseButton1Click:Once(function()
        self.itemDisplayVar.caseOpeningActive = false
        CasePage.Open(self)
        self.Location.CasesButton.Visible = true
        self.Location.KeysButton.Visible = true
        self.Location.SkinsButton.Visible = true
        seq.Visible = false
    end)
end

function CasePage:FillCaseFrame(index, skin)
    local itemFrame = self.Location.CaseOpeningSequence.ItemWheelDisplay.Wheel["Item_" .. index]
    local model = self.skinPage.CreateSkinFrameModel(self, skin)
    itemFrame:WaitForChild("ViewportFrame"):ClearAllChildren()
    model.Parent = itemFrame:WaitForChild("ViewportFrame")
end

function CasePage:OpenItemDisplay(caseFrame) -- Currently this is set up for cases only.
    if self.itemDisplayVar.active then return end
    self.itemDisplayVar.active = true -- turned off in CloseItemDisplay()

    local itemDisplayName = caseFrame:GetAttribute("ItemDisplayName") or caseFrame.Name
    self.itemDisplayFrame.ItemName.Text = string.upper(itemDisplayName)
    self.itemDisplayFrame.MainButton.Text = "OPEN"
    self.itemDisplayFrame.SecondaryButton.Text = "SELL"
    self.itemDisplayFrame.SecondaryButton.Visible = true
    self.itemDisplayFrame.IDLabel.Visible = false

    self.itemDisplayFrame.ItemDisplayImageLabel.Visible = false
    self.itemDisplayFrame.CaseDisplay.Visible = true
    self.itemDisplayFrame.CaseDisplay.ViewportFrame:ClearAllChildren()
    local model = ReplicatedStorage.Assets.Cases.weaponcase1.Model:Clone()
    model.Parent = self.itemDisplayFrame.CaseDisplay.ViewportFrame

    self.itemDisplayConns.MainButton = self.itemDisplayFrame.MainButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.caseOpeningActive then
            return
        end
        self.itemDisplayVar.caseOpeningActive = true
        CasePage.OpenCaseButtonClicked(self, caseFrame)
        self.itemDisplayVar.caseOpeningActive = false
    end)

    -- "Sell"
    self.itemDisplayConns.SecondaryButton = self.itemDisplayFrame.SecondaryButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.isSelling then
            return
        end
        self.itemDisplayVar.isSelling = true

        local caseName = caseFrame:GetAttribute("CaseName")
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
                Popup.burst("Successfully sold item for " .. tostring(shopItem.sell_sc) .. " SC!", 3)
                CasePage.CloseItemDisplay(self)
                CasePage.ConnectButtons(self)
            else
                Popup.burst("Could not sell item.", 3)
            end
            self.itemDisplayVar.isSelling = false
            confirmgui:Destroy()
            conns[1]:Disconnect()
        end)

        conns[2] = mainframe.DeclineButton.MouseButton1Click:Once(function()
            conns[1]:Disconnect()
            confirmgui:Destroy()
            self.itemDisplayVar.isSelling = false
            conns[2]:Disconnect()
        end)

        confirmgui.Enabled = true
    end)

    self.itemDisplayConns.BackButton = self.itemDisplayFrame.BackButton.MouseButton1Click:Connect(function()
        if self.itemDisplayVar.caseOpeningActive then
            return
        end
        CasePage.CloseItemDisplay(self)
    end)

    self.LastOpenPage = self.Location.Case.Visible and self.Location.Case or self.Location.Skin
    self.Location.Case.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.Visible = false
    self.Location.SkinsButton.Visible = false
    self.Location.KeysButton.Visible = false
    self.itemDisplayFrame.Visible = true
end

function CasePage:CloseItemDisplay()
    self.itemDisplayVar.active = false
    for _, v in pairs(self.itemDisplayConns) do
        v:Disconnect()
    end
    self.itemDisplayFrame.Visible = false
    self.LastOpenPage.Visible = true
    self.Location.CasesButton.Visible = true
    self.Location.SkinsButton.Visible = true
    self.Location.KeysButton.Visible = true
end

return CasePage
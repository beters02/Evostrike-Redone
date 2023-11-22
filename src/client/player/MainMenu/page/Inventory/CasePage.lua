local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local ShopInterface = require(Framework.Module.ShopInterface)
local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")

local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local Cases = game.ReplicatedStorage.Assets.Cases
local AttemptOpenCaseGui = ShopAssets:WaitForChild("AttemptOpenCase")

local CasePage = {}

function CasePage:ConnectButtons()
    for _, v in pairs(self.Location.Case.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        table.insert(self._bconnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
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
    self:OpenItemDisplay(caseFrame)
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
end

function CasePage:OpenCase(gotSkin, potentialSkins)
    self.itemDisplayVar.caseOpeningActive = true
    self:CloseItemDisplay()

    -- Prepare Var & Tween
    local crates = self.Location.CaseOpeningSequence.CaseDisplay.ViewportFrame.Crates
    local endCF = crates.PrimaryPart.CFrame - Vector3.new(0, 0, 1)
    local GrowTween = TweenService:Create(crates.PrimaryPart, TweenInfo.new(1), {CFrame = endCF})
    local WheelTween = TweenService:Create(self.Location.CaseOpeningSequence.ItemWheelDisplay.Wheel, TweenInfo.new(3, Enum.EasingStyle.Quad), {CanvasPosition = Vector2.new(2150, 0)})

    -- Fill Wheel CaseFrames with Models
    CasePage.FillCaseFrame(self, 1, gotSkin)
    local count = 1
    for _, v in pairs(potentialSkins) do
        count += 1
        self:FillCaseFrame(count, v)
    end

    -- Play Grow Tween
    self.Location.CaseOpeningSequence.CaseDisplay.Visible = true
    self.Location.CaseOpeningSequence.ItemWheelDisplay.Visible = false
    self.Location.CaseOpeningSequence.Visible = true
    GrowTween:Play()
    GrowTween.Completed:Wait()
    
    -- Play Wheel Tween
    self.Location.CaseOpeningSequence.CaseDisplay.Visible = false
    self.Location.CaseOpeningSequence.ItemWheelDisplay.Visible = true
    WheelTween:Play()
    WheelTween.Completed:Wait()

    -- play Received Item Screen
    task.delay(1, function()
        self:OpenCasePage()
        self.Location.CaseOpeningSequence.Visible = false
    end)
end

function CasePage:FillCaseFrame(index, skin)
    local itemFrame = self.Location.CaseOpeningSequence.ItemWheelDisplay.Wheel["Item_" .. index]
    local model = self.skinPage.CreateSkinFrameModel(self, skin.weapon, skin.knifeModel, skin.index)
    model.Parent = itemFrame:WaitForChild("ViewportFrame")
end

return CasePage
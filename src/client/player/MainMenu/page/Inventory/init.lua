--[[
    When creating a new knife, make sure to init in the init function
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local Cases = game.ReplicatedStorage.Assets.Cases
local ShopInterface = require(Framework.Module.ShopInterface)
local Popup = require(game:GetService("Players").LocalPlayer.PlayerScripts.MainMenu.popup) -- Main SendMessageGui Popup
local TweenService = game:GetService("TweenService")

local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local AttemptOpenCaseGui = ShopAssets:WaitForChild("AttemptOpenCase")

local inventory = {}
local skinPage = require(script:WaitForChild("SkinPage"))

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
        skinPage.OpenSkinPage(self)
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

    -- connect skin buttons
    for _, v in pairs(self.Location.Skin.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        table.insert(self._bconnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
            if not self.Location.Skin.Visible then return end
            skinPage.SkinFrameButtonClicked(self, v)
        end))
    end

    -- connect case buttons
    for _, v in pairs(self.Location.Case.Content:GetChildren()) do
        if not v:IsA("Frame") or v.Name == "ItemFrame" then continue end
        table.insert(self._bconnections, v:WaitForChild("Button").MouseButton1Click:Connect(function()
            if not self.Location.Case.Visible then return end
            self:CaseButtonClicked(v)
        end))
    end

    --TODO: connect key buttons
end

function inventory:DisconnectButtons()
    for _, v in pairs(self._bconnections) do
        v:Disconnect()
    end
    self._bconnections = {}
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

-- [[ CASE PAGE ]]
function inventory:OpenCasePage()
    self.Location.Case.Visible = true
    self.Location.Key.Visible = false
    self.Location.Skin.Visible = false
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

function inventory:CreateCaseFrame(case: string)
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

function inventory:CaseButtonClicked(caseFrame)
    self:OpenItemDisplay(caseFrame)
end

function inventory:OpenCaseButtonClicked(caseFrame)
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
                    self:OpenCase(openedSkin, potentialSkins)
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


-- [[ CASE OPENING SEQUENCE ]]
function inventory:OpenCase(gotSkin, potentialSkins)
    self.itemDisplayVar.caseOpeningActive = true
    self:CloseItemDisplay()

    -- Prepare Var & Tween
    local crates = self.Location.CaseOpeningSequence.CaseDisplay.ViewportFrame.Crates
    local endCF = crates.PrimaryPart.CFrame - Vector3.new(0, 0, 1)
    local GrowTween = TweenService:Create(crates.PrimaryPart, TweenInfo.new(1), {CFrame = endCF})
    local WheelTween = TweenService:Create(self.Location.CaseOpeningSequence.ItemWheelDisplay.Wheel, TweenInfo.new(3, Enum.EasingStyle.Quad), {CanvasPosition = Vector2.new(2150, 0)})

    -- Fill Wheel CaseFrames with Models
    self:FillCaseFrame(1, gotSkin)
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

function inventory:FillCaseFrame(index, skin)
    local itemFrame = self.Location.CaseOpeningSequence.ItemWheelDisplay.Wheel["Item_" .. index]
    local model = self:CreateSkinFrameModel(skin.weapon, skin.knifeModel, skin.index)
    model.Parent = itemFrame:WaitForChild("ViewportFrame")
end

return inventory
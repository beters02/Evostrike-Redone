local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Strings = require(Framework.Module.lib.fc_strings)

local InventoryInterface = require(Framework.Module.InventoryInterface)
local ShopAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Shop")
local ShopSkins = require(ShopAssets.Skins)
local Cases = game.ReplicatedStorage.Assets.Cases
local Rarity = require(ShopAssets.Rarity)

local SkinFrames = require(script.Parent.Parent.Skin.Frames)
local Config = require(script.Parent.Config)

function fillCaseSeqFrame(self, skin, index)
    if index/10 < 1 then
        index = "0" .. tostring(index)
    end

    local itemFrame = self.Inventory.Frame.CaseOpeningSequence.ItemWheelDisplay.Wheel["Item_" .. tostring(index)]
    local model = SkinFrames.CreateSkinFrameModel(skin)
    itemFrame:WaitForChild("ViewportFrame"):ClearAllChildren()
    model.Parent = itemFrame:WaitForChild("ViewportFrame")
end

return function(self, gotSkin, potentialSkins)
    self:CloseItemDisplay()
    self.Inventory:CloseSubPage()
    self.ItemDisplay.Var.CaseOpeningActive = true

    -- Prepare Var & Tween
    local seq = self.Inventory.Frame.CaseOpeningSequence

    local seqItem = seq.ItemDisplay
    seqItem.Display.ViewportFrame:ClearAllChildren()

    local seqCase = seq.CaseDisplay
    local caseViewportFrame = seqCase.ViewportFrame
    caseViewportFrame:ClearAllChildren()

    local seqWheel = seq.ItemWheelDisplay
    seqWheel.Wheel.CanvasPosition = Vector2.new(0,0)

    local crates: Model = Cases.weaponcase1.Model:Clone()
    crates.Parent = caseViewportFrame
    crates:PivotTo(Config.DefaultOpeningCaseCFrame)

    local endCF = crates.PrimaryPart.CFrame - Vector3.new(0, 0, 1)
    local GrowTween = TweenService:Create(crates.PrimaryPart, TweenInfo.new(1), {CFrame = endCF})

    local WheelAbsolute = seqWheel.Wheel.AbsoluteCanvasSize
    local WheelFinalPos = WheelAbsolute.X / 1.583-- Arbiturary value found via testing
    WheelFinalPos = Vector2.new(WheelFinalPos, 0)
    local WheelTween = TweenService:Create(seqWheel.Wheel, TweenInfo.new(3, Enum.EasingStyle.Quad), {CanvasPosition = WheelFinalPos})

    -- Fill Wheel CaseFrames with Model
    local gotParsed = InventoryInterface.ParseSkinString(gotSkin)
    fillCaseSeqFrame(self, gotParsed, #potentialSkins)  -- fill second to last frame with got skin
    fillCaseSeqFrame(                                   -- fill last frame with last potential skin
        self,
        InventoryInterface.ParseSkinString(potentialSkins[#potentialSkins]),
        #potentialSkins + 1
    )

    -- Get default item frame sizes for tick sound
    local gridPad = 0.05
    local xSizeOffset = workspace.CurrentCamera.ViewportSize.X * (0.061 + gridPad)

    for i = 1, #potentialSkins - 1 do
        fillCaseSeqFrame(
            self,
            InventoryInterface.ParseSkinString(potentialSkins[i]),
            i
        )
    end

    -- Fill ItemDisplay with Got Item
    seqItem.ItemName.Text =  Strings.firstToUpper(gotParsed.model) .. " | " .. Strings.firstToUpper(gotParsed.skin)

    local itemDisplayModel = SkinFrames.CreateSkinFrameModel(gotParsed)
    itemDisplayModel.Parent = seqItem.Display.ViewportFrame

    -- Set rarity color/text
    local rarity = ShopSkins.GetSkinFromInvString(gotParsed.unsplit).rarity
    local rarityColor = Rarity[rarity].color
    seqItem.RarityLabel.Text = rarity
    seqItem.RarityLabel.TextColor3 = rarityColor

    -- Case Opening Sequence
    self.Inventory.Frame.Case.Visible = false
    self.Inventory.Frame.Key.Visible = false
    self.Inventory.Frame.Skin.Visible = false
    self.Inventory.Frame.CasesButton.Visible = false
    self.Inventory.Frame.KeysButton.Visible = false
    self.Inventory.Frame.SkinsButton.Visible = false
    --self.Inventory.Frame.NextPageNumberButton.Visible = false
    --self.Inventory.Frame.PreviousPageNumberButton.Visible = false
    --self.Inventory.Frame.CurrentPageNumberLabel.Visible = false
    seq.Visible = true

    -- Play Grow Tween
    seqCase.Visible = true
    seqWheel.Visible = false
    seqItem.Visible = false
    GrowTween:Play()
    GrowTween.Completed:Wait()
    self.Inventory.Main:PlayButtonSound("WoodImpact1")
    
    -- Play Wheel Tween
    local lastTickPos = 0
    task.spawn(function() -- ticking sound
        self.Inventory.Main:PlayButtonSound("WheelTick1")
        while lastTickPos do
            if seqWheel.Wheel.CanvasPosition.X - lastTickPos >= xSizeOffset then
                lastTickPos = seqWheel.Wheel.CanvasPosition.X
                self.Inventory.Main:PlayButtonSound("WheelTick1")
            end
            task.wait()
        end
    end)
    seqCase.Visible = false
    seqWheel.Visible = true
    WheelTween:Play()
    WheelTween.Completed:Wait()
    lastTickPos = false

    -- play Received Item Screen
    self.Inventory.Main:PlayButtonSound("ItemReceive1")
    seqWheel.Visible = false
    seqItem.Visible = true

    seqItem.BackButton.MouseButton1Click:Once(function()
        self.ItemDisplay.Var.CaseOpeningActive = false
        self.Inventory.Frame.CasesButton.Visible = true
        self.Inventory.Frame.KeysButton.Visible = true
        self.Inventory.Frame.SkinsButton.Visible = true
        self.Inventory:OpenSubPage("Case")
        self.Inventory:EnableSubPageButtons()
        seq.Visible = false
    end)
end
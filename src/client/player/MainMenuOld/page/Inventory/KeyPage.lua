local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cases = game.ReplicatedStorage.Assets.Cases

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

local KeyPage = {}

function KeyPage:init(frame)
    self.KeyPageFrames = {}
    KeyPage.MainFrame = frame
end

function KeyPage:Clear()
    for _, v in pairs(self.KeyPageFrames) do
        v:Destroy()
    end
    self.KeyPageFrames = {}
end

function KeyPage:Open()
    self.Location.Case.Visible = false
    self.Location.Key.Visible = true
    self.Location.Skin.Visible = false
    self.Location.KeysButton.BackgroundColor3 = Color3.fromRGB(80, 96, 118)
    self.Location.SkinsButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
    self.Location.CasesButton.BackgroundColor3 = Color3.fromRGB(136, 164, 200)
end

function KeyPage:Update(playerInventory)
    KeyPage.Clear(self)
    for i, case in pairs(playerInventory.key) do
        self.KeyPageFrames[i] = KeyPage.CreateKeyFrame(self, case)
    end
end

function KeyPage:CreateKeyFrame(case: string)
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

return KeyPage
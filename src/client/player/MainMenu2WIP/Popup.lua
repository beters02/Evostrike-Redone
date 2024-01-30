local TweenService = game:GetService("TweenService")
function createPopupGui()
    local gui = Instance.new("ScreenGui")
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 12
    gui.Enabled = true
    local lbl = Instance.new("TextLabel", gui)
    lbl.Position = UDim2.fromScale(.339, .643)
    lbl.Size = UDim2.fromScale(.32, .047)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextScaled = true
    lbl.FontFace = Font.new("Gotham SSm", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    return gui
end

local Popup = {}

function Popup.new(plr, txt, len)
    local iti = TweenInfo.new(0.8)
    local gui = createPopupGui()
    gui.TextLabel.TextTransparency = 1
    gui.TextLabel.Text = txt

    local int = TweenService:Create(gui.TextLabel, iti, {TextTransparency = 0})
    local out = TweenService:Create(gui.TextLabel, iti, {TextTransparency = 1})

    gui.Parent = plr.PlayerGui
    int:Play()
    int.Completed:Wait()
    task.delay(len, function()
        out:Play()
        out.Completed:Wait()
        gui:Destroy()
    end)
    return gui
end

return Popup
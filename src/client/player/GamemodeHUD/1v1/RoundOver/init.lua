local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rbxui = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("rbxui"))

local RoundOver = {}
RoundOver.__index = RoundOver

local function getStroke()
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(22, 23, 29)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.LineJoinMode = Enum.LineJoinMode.Miter
    stroke.Thickness = 1.5
    stroke.Transparency = 0
    return stroke
end

local function getAspectRatio()
    local ar = Instance.new("UIAspectRatioConstraint")
    ar.AspectType = Enum.AspectType.FitWithinMaxSize
    ar.DominantAxis = Enum.DominantAxis.Width
    ar.AspectRatio = 2
    return ar
end

function RoundOver.init(winner, loser)
    local self = setmetatable({}, RoundOver)
    local text = winner == Player and "YOU WON!" or "YOU LOST!"

    local gui = rbxui.Gui.new({Name = "RoundOverUI"})
    local mainPage = rbxui.Page.new(gui, {
        Name = "MainPage",
        Size = UDim2.fromScale(0.3, 0.4),
        Position = UDim2.fromScale(0.5, 0.3),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = Color3.fromHex("60708B"),
        BackgroundTransparency = 0.45,
    })
    local topLabel = rbxui.Label.new(mainPage, {
        Name = "TopLabel",
        Size = UDim2.fromScale(0.399*1.2, 0.132*1.2),
        Position = UDim2.fromScale(0.498, 0.198),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundTransparency = 1
    }, {
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Michroma,
        Size = UDim2.fromScale(0.8, 0.8)
    })
    getStroke().Parent = topLabel.FitText.Instance
    getAspectRatio().Parent = mainPage.Instance
    gui:Parent()
    gui:Enable()
    rbxui.Tag.Add(gui, "DestroyOnRoundStart")

    self.rbxui = gui
    return self
end

function RoundOver:Destroy()
    self.rbxui:Destroy()
    self = nil
end

return RoundOver
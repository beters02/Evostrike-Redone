--@summary Create a new Option Item Frame UI Component, takes the option key and it's current value.
--         Automatically creates a text box or true/false button

local OptionItemFrame = {}
OptionItemFrame.__index = {}

function OptionItemFrame.new(key, currentValue)
    local self = {}
    self.Connections = {}

    self.Frame = Instance.new("Frame", game:GetService("ReplicatedStorage"))
    self.Frame.Size = UDim2.fromScale(1, 0.015)
    self.Frame.BackgroundTransparency = 1

    local keyLabel = Instance.new("TextLabel", self.Frame)
    keyLabel.Text = tostring(key)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Name = "KeyLabel"
    keyLabel.Size = UDim2.fromScale(0.5, 1)

    return self
end

function OptionItemFrame:Disconnect()
    for _, v in pairs(self.Connections) do
        v:Disconnect()
    end
    self.Connections = {}
end

-- Large Option Values (ex: Crosshair.Red)
local TextBoxFrame = setmetatable({}, OptionItemFrame)
TextBoxFrame.__index = TextBoxFrame

function TextBoxFrame.new(key, currentValue)
    local self = setmetatable(OptionItemFrame.new(key, currentValue), TextBoxFrame)

    local valueLabel = Instance.new("TextLabel", self.Frame)
    valueLabel.Text = tostring(currentValue)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.fromScale(0.5, 1)
    valueLabel.Position = UDim2.fromScale(0.5, 0)

    return self
end

-- Single Key Option Values
local KeybindTextBoxFrame = setmetatable({}, TextBoxFrame)
KeybindTextBoxFrame.__index = KeybindTextBoxFrame

-- True/False Option Values
local BooleanFrame = setmetatable({}, OptionItemFrame)
BooleanFrame.__index = BooleanFrame

function BooleanFrame.new(key, currentValue)
    local self = setmetatable(OptionItemFrame.new(key, currentValue), BooleanFrame)

    local trueButton = Instance.new("TextButton", self.Frame)
    trueButton.Name = "TrueButton"
    trueButton.Text = "true"


    return self
end

function createTextBox(key, currentValue)
    
end

function createTrueFalseButton(key, currentValue)
    
end

function createKeybindTextBox(key, currentValue)
    
end

function CreateOptionItemFrame(key, currentValue)
    local itemFrame = Instance.new("Frame")
    itemFrame.Size = UDim2.fromScale(1, 0.053)
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Parent = itemFrame
    keyLabel.Size = UDim2.fromScale(0.5, 1)
    keyLabel.Text = tostring(key)

    local valueObject
    if type(currentValue) == "boolean" then
        valueObject = createTrueFalseButton()
    end
end

return CreateOptionItemFrame
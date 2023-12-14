local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
-- [[ TODO ]]
-- Add UIConstraint Functionality
-- Add Updating Variables for text related components -- VariableLink ?
-- Make FitText the default text option for Button and remove ButtonLabel, as well as remove public access to FitText

-- INFO
--@creator  beters
--@summary  RBXUI is a simple solution for creating roblox UI via code.
--@tutorial
--[[ =
    - rbxui is to be used on the client only.
    - Button Binds are automatically disconnected when the parent page is closed.
--= ]]

-- Components
local Gui
local Page
local Button
local FitText
local Label
local ButtonLabel

-- Features
local Tag

-- Script Functions
function setFitText(self, str) self.Instance.Text = str end
function setLabelText(self, str) self.FitText.Instance.Text = str end
function setComponentSize(self, size) self.Instance.Size = size end
function setComponentPos(self, pos, anchorPoint)
    if pos then self.Instance.Position = pos end
    if anchorPoint then self.Instance.AnchorPoint = anchorPoint end
end

--@function Apply RBX & SizePreset/PositionPreset properties to an instance
function applyRBXPropertiesInstance(instance, rbxprop, defaults)
    rbxprop = rbxprop or {}
    inheritDefaultProperties(defaults, rbxprop)
    applyRBXProperties(instance, rbxprop)
    if rbxprop.SizePreset then instance.Size = Gui.SizeEnum[rbxprop.SizePreset] end
    if rbxprop.PositionPreset then
        instance.Position = Gui.PosEnum[rbxprop.PositionPreset].Position
        instance.AnchorPoint = Gui.PosEnum[rbxprop.PositionPreset].AnchorPoint
    end
end

--@function Apply RBX properties to a table
function applyRBXProperties(tab, prop)
    if not tab or not prop then return end
    for i, v in pairs(prop) do
        pcall(function() tab[i] = v end)
    end
end

--@function Has an already existing rbxprop inherit defaults
function inheritDefaultProperties(defaults, rbxprop)
    if not defaults or not rbxprop then return end
    for i, v in pairs(defaults) do
        if rbxprop[i] ~= nil then continue end
        rbxprop[i] = v
    end
    return rbxprop
end

--[[GUI COMPONENT]]
--@summary Gui's are the base component of any UI made within RBXUI
--@require Gui:Enable() automatically opens the Main Page if there is one and disables the rest. Set EnableOpenMainPage to false to disable this feature.
Gui = {}
Gui.__index = Gui
Gui.new = function(rbxprop)
    assert(rbxprop, "Must add a properties table with a Name key,v.")
    assert(rbxprop.Name, "Must define a name for the GUI.")

    local self = setmetatable({}, Gui)
    self.Name = rbxprop.Name
    self.EnableOpenMainPage = true

    self.Instance = Instance.new("ScreenGui")
    applyRBXPropertiesInstance(self.Instance, rbxprop, {
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Enabled = false
    })

    self.Folders = {Pages = true}
    for i, _ in pairs(self.Folders) do
        self.Folders[i] = Instance.new("Folder", self.Instance)
        self.Folders[i].Name = i
    end

    self.Pages = {MainPage = false}
    self.CurrentPage = false
    return self
end

--@function Parent a gui to a player's playergui.
function Gui:Parent(player: Player?)
    player = player or game.Players.LocalPlayer
    self.Instance.Parent = player.PlayerGui
end

function Gui:Enable()
    if self.EnableOpenMainPage and self.Pages.MainPage then
        self.Pages.MainPage:Open()
    end
    self.Instance.Enabled = true
end

function Gui:Disable()
    if self.CurrentPage then
        self.CurrentPage:Close()
    end
    self.Instance.Enabled = false
end

--@function Set the Gui's background to an image
function Gui:SetBackgroundImage(imgid)
    local imglabel
    if not self.Instance:FindFirstChild("BACKGROUND_IMAGE") then
        imglabel = Instance.new("ImageLabel", self.Instance)
        imglabel.Name = "BACKGROUND_IMAGE"
        imglabel.Size = UDim2.fromScale(1, 1)
        imglabel.AnchorPoint = Vector2.new(0.5,0.5)
        imglabel.Position = UDim2.fromScale(0.5,0.5)
    end
    imglabel.Image = imgid
    imglabel.Visible = true
    return imglabel
end

function Gui:Destroy()
    Tag.RemoveAllTags(self)
    self:Disable()
    for i, v in pairs(self.Pages) do
        v:Close()
    end
    self.Instance:Destroy()
    self = nil
end

--@enum Preset Gui Sizes
Gui.SizeEnum = {
    Full = UDim2.fromScale(1, 1),
    Half = UDim2.fromScale(0.5, 0.5),
    Quarter = UDim2.fromScale(0.25, 0.25),
    Point = UDim2.fromScale(0.1, 0.1)
}

--@enum Preset Gui Positions
Gui.PosEnum = {
    Middle = {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5)},
    Top = {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0)},
    Bottom = {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1)}
}

--[[PAGE COMPONENT]]
--@summary Pages are Frames that are children of the base Gui.
Page = {}
Page.__index = Page
Page.new = function(gui, rbxprop)
    assert(rbxprop, "Must add a properties table with a Name key,v.")
    assert(rbxprop.Name, "Must define a name for the Page.")
    rbxprop = rbxprop or {}

    local self = setmetatable({}, Page)
    self.Name = rbxprop.Name
    self.Main = gui
    self.Main.Pages[rbxprop.Name] = self

    self.Instance = Instance.new("Frame", gui.Folders.Pages)
    applyRBXPropertiesInstance(self.Instance, rbxprop, {
        Size = Gui.SizeEnum.Half,
        Position = Gui.PosEnum.Middle.Position,
        Visible = false,
        BackgroundTransparency = 1
    })

    self.Buttons = {}
    self.Labels = {}
    self.Folders = {Buttons = true, Labels = true}
    for i, _ in pairs(self.Folders) do
        self.Folders[i] = Instance.new("Folder", self.Instance)
        self.Folders[i].Name = i
    end

    self._nextUpdate = tick()
    self.CoreUpdateLoop = RunService.RenderStepped:Connect(function(dt)
        local t = tick()
        if t >= self._nextUpdate then
            self._nextUpdate = t + 1/30
        end

        -- update variables function here
    end)

    return self
end

--@function Open a page. Closes all other pages within the GUI.
function Page:Open()
    if self.Main.CurrentPage then
        self.Main.CurrentPage:Close()
    end
    self:Connect()
    self.Instance.Visible = true
    self.Main.CurrentPage = self
end

--@function Close a page. No special functionality.
function Page:Close()
    self:Disconnect()
    self.Instance.Visible = false
end

--@function Connect all Buttons of a page.
function Page:Connect()
    for _, v in pairs(self.Buttons) do
        v:Connect()
    end
end

--@function Disconnect all the Buttons of a page.
function Page:Disconnect()
    for _, v in pairs(self.Buttons) do
        v:Disconnect()
    end
end

--@function Set the position or anchorPoint
function Page:SetPos(pos, anchorPoint)
    return setComponentPos(self, pos, anchorPoint)
end

--@function Set the size
function Page:SetSize(size)
    return setComponentSize(self, size)
end

--[[BUTTON COMPONENT]]
--@summary Buttons are a Page Component, must be parented to a Page
Button = {}
Button.__index = Button
Button.new = function(page, rbxprop)
    assert(rbxprop, "Must add a properties table with a Name key,v.")
    assert(rbxprop.Name, "Must define a name for the Button.")
    rbxprop = rbxprop or {}

    local self = setmetatable({}, Button)
    self.Name = rbxprop.Name
    self.Main = page
    self.Main.Buttons[rbxprop.Name] = self
    self._connections = {}
    self._binding = false

    self.Instance = Instance.new("TextButton", page.Folders.Buttons)
    applyRBXPropertiesInstance(self.Instance, rbxprop, {
        Size = Gui.SizeEnum.Point,
        Position = Gui.PosEnum.Middle.Position,
        ZIndex = 2,
        Visible = true
    })
    return self
end

function Button:Connect()
    if not self._binding then
        return
    end
    table.insert(self._connections, self.Instance.MouseButton1Click:Connect(function()
        self._binding()
    end))
end

function Button:Disconnect()
    for _, c in pairs(self._connections) do
        c:Disconnect()
    end
end

--@function Bind an action to a button.
function Button:Bind(func)
    self._binding = func
end

--@function Unbind an action from a button.
function Button:Unbind()
    self._binding = false
end

--@function Sets the button's functionality to open a different Page
--@summary Bind shorthand for linking pages.
function Button:LinkPage(pageName)
    self:Bind(function()
        self.Main.Main.Pages[pageName]:Open()
    end)
end

--@function Set the position or anchorPoint
function Button:SetPos(pos, anchorPoint)
    return setComponentPos(self, pos, anchorPoint)
end

--@function Set the size
function Button:SetSize(size)
    return setComponentSize(self, size)
end

function Button:SetText(str)
    self.Instance.Text = str
end

--[[LABEL COMPONENT]]
--@summary A Label is a FitText in a Roblox Frame
--          Text is automatically set to the Name
Label = {}
Label.__index = Label
Label.new = function(page, rbxprop, textprop)
    assert(rbxprop, "Must add a properties table with a Name key,v.")
    assert(rbxprop.Name, "Must define a name for the Label.")
    textprop = textprop or {}

    local self = setmetatable({}, Label)
    self.Name = rbxprop.Name
    self.Main = page
    self.Main.Labels[rbxprop.Name] = self
    self.Instance = Instance.new("Frame", page.Folders.Labels)

    applyRBXPropertiesInstance(self.Instance, rbxprop, {
        Position = Gui.PosEnum.Middle.Position,
        Size = Gui.SizeEnum.Point,
        Visible = true,
        ZIndex = 2
    })

    self.FitText = FitText.new(self, inheritDefaultProperties({
        Text = rbxprop.Name,
        Position = Gui.PosEnum.Middle.Position,
        AnchorPoint = Gui.PosEnum.Middle.AnchorPoint,
        ZIndex = 3
    }, textprop))
    
    return self
end

function Label:SetText(str)
    return setLabelText(self, str)
end

--@function Set the position or anchorPoint
function Label:SetPos(pos, anchorPoint)
    return setComponentPos(self, pos, anchorPoint)
end

--@function Set the size
function Label:SetSize(size)
    return setComponentSize(self, size)
end

--[[BUTTON LABEL COMPONENT]]
--@summary A Button Label is a FitText inside of a RBXUI Button
--          rbxprop are applied to the Button, do button.FitText... for FitText changes
ButtonLabel = {}
ButtonLabel.__index = Button
ButtonLabel.new = function(page, rbxprop, textprop)
    assert(rbxprop, "Must add a properties table with a Name key,v.")
    assert(rbxprop.Name, "Must define a name for the Button Label.")
    textprop = textprop or {}

    inheritDefaultProperties({
        Name = rbxprop.Name,
        Size = Gui.SizeEnum.Point,
        Position = Gui.PosEnum.Middle.Position,
        AnchorPoint = Vector2.zero,
        TextTransparency = 1,
        ZIndex = 2
    }, rbxprop)
    inheritDefaultProperties({
        Text = rbxprop.Name,
        BackgroundTransparency = 1,
        ZIndex = 3
    }, textprop)
    
    local button = Button.new(page, rbxprop)
    button.FitText = FitText.new(button, textprop)
    return setmetatable(button, ButtonLabel)
end

function ButtonLabel:SetText(str)
    return setLabelText(self, str)
end

--@function Set the position or anchorPoint
function ButtonLabel:SetPos(pos, anchorPoint)
    return setComponentPos(self, pos, anchorPoint)
end

--@function Set the size
function ButtonLabel:SetSize(size)
    return setComponentSize(self, size)
end

--[[FIT TEXT COMPONENT]]
--@summary Create a Text Element for a component that fits correctly while TextScaled = true
--          Can be applied to any component.
FitText = {}
FitText.__index = FitText
FitText.new = function(component, rbxprop)
    local self = setmetatable({}, FitText)
    self.Name = component.Name
    local text = Instance.new("TextLabel", component.Instance)
    applyRBXPropertiesInstance(text, rbxprop, {
        Text = "FitText",
        Position = Gui.PosEnum.Middle.Position,
        AnchorPoint = Gui.PosEnum.Middle.AnchorPoint,
        Size = UDim2.fromScale(0.8, 0.8),
        Visible = true,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        TextScaled = true,
        ZIndex = component.Instance.ZIndex + 1
    })
    self.Instance = text
    self.Main = component
    return self
end

function FitText:SetText(str)
    return setFitText(self, str)
end

--@function Set the position or anchorPoint
function FitText:SetPos(pos, anchorPoint)
    return setComponentPos(self, pos, anchorPoint)
end

--@function Set the size
function FitText:SetSize(size)
    return setComponentSize(self, size)
end

--[[TAG]]
Tag = {tags = {}}
Tag.__index = Tag

function Tag.Add(component, tag)
    if not Tag.tags[tag] then
        Tag.tags[tag] = {}
    end
    Tag.tags[tag][component.Name] = component
    if not component.Tags then
        component.Tags = {}
    end
    component.Tags[tag] = true
end

function Tag.Remove(component, tag)
    if Tag.tags[tag] and Tag.tags[tag][component.Name] then
        Tag.tags[tag][component.Name] = nil
    end
    if component.Tags and component.Tags[tag] then
        component.Tags[tag] = nil
    end
end

function Tag.RemoveAllTags(component)
    if component.Tags then
        for i, _ in pairs(component.Tags) do
            Tag.Remove(component, i)
        end
    end
end

function Tag.DestroyAllIn(tag)
    if Tag.tags[tag] then
        for i, v in pairs(Tag.tags[tag]) do
            v:Destroy()
            Tag.tags[tag][i] = nil
        end
    end
end

--[[MODULE]]
local RBXUI = {
    Gui = Gui,
    Page = Page,
    Button = Button,
    FitText = FitText,
    Label = Label,
    ButtonLabel = ButtonLabel,
    Enum = {
        Pos = Gui.PosEnum,
        Size = Gui.SizeEnum
    },
    Tag = Tag
}

return RBXUI
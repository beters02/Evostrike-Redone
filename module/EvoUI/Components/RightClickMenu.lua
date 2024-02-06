--[[
    Right Click UI:

    Instantiate with RightClickMenu.new()
    Set Button Actions with Menu.Button1Clicked = function(self) end
    Enable with Menu:Enable()
    Destroy with Menu:Destroy()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Math = require(Framework.Module.lib.fc_math)
local RightClickGui = ReplicatedStorage.Assets.UI:WaitForChild("RightClickGui")

local RightClickMenu = {}
RightClickMenu.__index = RightClickMenu

function RightClickMenu.new(plr)
    local self = setmetatable({}, RightClickMenu)
    self.Connections = {}
    self.Gui = RightClickGui:Clone()
    self.MainFrame = self.Gui:WaitForChild("MainFrame")
    self.Button1 = self.MainFrame:WaitForChild("Button1")
    self.Button2 = self.MainFrame:WaitForChild("Button2")

    local mp = UserInputService:GetMouseLocation()
    local mpVec2 = Math.offsetToScaleNumber(mp.X, mp.Y)
    self.MainFrame.Position = UDim2.new(mpVec2.X, 8, mpVec2.Y, 0)
    self.Gui.Parent = plr.PlayerGui
    self.Gui.Enabled = false
    return self
end

function RightClickMenu:Enable()

    local didClickButton = false

    self.Gui.Enabled = true

    self.Connections.B1M1 = self.Button1.MouseButton1Click:Connect(function()
        didClickButton = true
        self:Button1Clicked()
    end)
    self.Connections.B2M1 = self.Button2.MouseButton1Click:Connect(function()
        didClickButton = true
        self:Button2Clicked()
    end)
    self.Connections.ClickOff = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2 then
            task.delay(.1, function()
                if didClickButton then
                    didClickButton = false
                else
                    self:Destroy()
                end
            end)
        end
    end)
end

function RightClickMenu:Disable()
    for _, v in pairs(self.Connections) do
        v:Disconnect()
    end
    self.Gui.Enabled = false
end

function RightClickMenu:Destroy()
    self:Disable()
    self.Gui:Destroy()
end

function RightClickMenu:Button1Clicked() end
function RightClickMenu:Button2Clicked() end

return RightClickMenu
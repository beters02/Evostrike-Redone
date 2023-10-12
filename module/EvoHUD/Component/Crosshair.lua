-- [[ Crosshair HUD Component ]]

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)
local RunService = game:GetService("RunService")

local Crosshair = {}

-- [[ Component ]]
-- Create a new Crosshair
function Crosshair:init(hudClass)
    self.gui = Crosshair._getUI(self)
    self.connections = {}
    self.resolution = self.hud.AbsoluteSize
    self.hairs = {}
    self:UpdateOptions()
    self:UpdateGui()
    return self
end

function Crosshair:Connect()
    self.connections[1] = RunService.RenderStepped:Connect(function()
        -- update when resolution is changed
        if self.hud.AbsoluteSize ~= self.resolution then
            self.resolution = self.hud.AbsoluteSize
            self:UpdateOptions()
            self:UpdateGui()
        end
    end)
end

function Crosshair:Disconnect()
    for _, v in ipairs(self.connections) do
        v:Disconnect()
    end
    table.clear(self.connections)
end

-- [[ Crosshair ]]
function Crosshair:UpdateOptions()
    for i, v in pairs(PlayerData:GetPath(self.player, "options.crosshair")) do
        self[i] = v
    end
end

function Crosshair:UpdateGui()

    -- update pos
	local verticalOffset, horizontalOffset = UDim2.fromOffset(0, self.gap + (self.size/2)), UDim2.fromOffset(self.gap + (self.size/2), 0)
    self.origin = self:_getOrigin()
	
	self.hairs.top.Position = self.origin + -verticalOffset
	self.hairs.bottom.Position = self.origin + verticalOffset
	self.hairs.right.Position = self.origin + -horizontalOffset
	self.hairs.left.Position = self.origin + horizontalOffset
    self.hairs.dot.Position = self.origin

    -- update size and thickness
    self.hairs.dot.Size = UDim2.fromOffset(self.thickness, self.thickness)
    self.hairs.left.Size = UDim2.fromOffset(self.size, self.thickness)
    self.hairs.right.Size = UDim2.fromOffset(self.size, self.thickness)

    -- This is the bottom and top frames so we have to make them thinner in width and larger in height
	self.hairs.top.Size = UDim2.fromOffset(self.thickness, self.size)
	self.hairs.bottom.Size = UDim2.fromOffset(self.thickness, self.size)
    
    -- update color and outline
    for i, v in pairs(self.hairs) do
        v = v :: Frame
        v.BackgroundColor3 = Color3.fromRGB(self.red, self.green, self.blue)
        v.BorderSizePixel = self.outline and 1 or 0
        v.BorderColor3 = Color3.new(0,0,0)
    end

    -- set dot
    self.hairs.dot.BackgroundTransparency = self.dot and 0 or 1
end

-- [[ Util ]]
function Crosshair._getOrigin(self)
    return UDim2.fromOffset(self.resolution.X / 2, self.resolution.Y / 2)
end

function Crosshair._getUI(self)
    local crosshairgui = self.hud:FindFirstChild("Crosshair")
    if crosshairgui then
        crosshairgui:Destroy()
    end
    crosshairgui = Instance.new("ScreenGui")
    crosshairgui.IgnoreGuiInset = true
    crosshairgui.Name = "Crosshair"
    crosshairgui.Parent = self.hud
    crosshairgui.Enabled = true
    return crosshairgui
end

function Crosshair._getHairs(self)
	return {
		top = self:_getHairFrame(),
		bottom = self:_getHairFrame(),
		right = self:_getHairFrame(),
		left = self:_getHairFrame(),
        dot = self:_getHairFrame()
	}
end

function Crosshair._getHairFrame(self): Frame
	local frame = Instance.new("Frame") -- If you wanted to make something like a shotgun crosshair, you'd probably need a ImageLabel instead
	frame.Name = "_hair"
	frame.Size = UDim2.fromOffset(5, 1)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Parent = self.crosshairgui
	return frame
end

return Crosshair
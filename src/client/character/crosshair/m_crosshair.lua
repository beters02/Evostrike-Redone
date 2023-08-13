local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local RunService = game:GetService("RunService")

local crosshair = {}
crosshair._isInit = false

-- length, thickness
local defaultSize = Vector2.new(5, 1)

function crosshair.initialize(hud)
    local self = crosshair
    self.hud = hud
    self.resolution = self.hud.AbsoluteSize
    self.origin = UDim2.fromOffset(self.resolution.X / 2, self.resolution.Y / 2)
    self.hairs = {}

    local clientPlayerDataModule = require(Framework.shm_clientPlayerData.Location)
	if not clientPlayerDataModule.stored then repeat task.wait() until clientPlayerDataModule.stored end

    for i, v in pairs(clientPlayerDataModule.stored.options.crosshair) do
        self[i] = v
    end

    self.crosshairgui = Instance.new("ScreenGui")
    self.crosshairgui.IgnoreGuiInset = true
    self.crosshairgui.Name = "Crosshair"
    self.crosshairgui.Parent = hud
    self.crosshairgui.Enabled = true

    local top, bottom, right, left, dot = self:newFrame(), self:newFrame(), self:newFrame(), self:newFrame(), self:newFrame()
	self.hairs = {
		top = top,
		bottom = bottom,
		right = right,
		left = left,
        dot = dot
	}

    self:updateCrosshair()

    self._isInit = true
    crosshair = self
    return self
end

-- Logic

function crosshair:newFrame(): Frame
	local frame = Instance.new("Frame") -- If you wanted to make something like a shotgun crosshair, you'd probably need a ImageLabel instead
	frame.Name = "_hair"
	frame.Size = UDim2.fromOffset(defaultSize.X, defaultSize.Y)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Parent = self.crosshairgui
	return frame
end

function crosshair:updateCrosshair(dataKey: string, newValue: any)
  
    if dataKey and self[dataKey] then
        self[dataKey] = newValue
    end

    -- update pos
	local verticalOffset, horizontalOffset = UDim2.fromOffset(0, self.gap + (self.size/2)), UDim2.fromOffset(self.gap + (self.size/2), 0)
    local hairs = self.hairs
    local origin = self.origin
	
	hairs.top.Position = origin + -verticalOffset
	hairs.bottom.Position = origin + verticalOffset
	hairs.right.Position = origin + -horizontalOffset
	hairs.left.Position = origin + horizontalOffset

    if self.dot then
        if not hairs.dot then hairs.dot = self:newFrame() end
        hairs.dot.Position = UDim2.fromScale(0.5, 0.5)
        hairs.dot.Size = UDim2.fromOffset(1, 1)
    else
        if hairs.dot then hairs.dot:Destroy() hairs.dot = nil end
    end

    -- update size and thickness
    hairs.left.Size = UDim2.fromOffset(self.size, self.thickness)
    hairs.right.Size = UDim2.fromOffset(self.size, self.thickness)

    -- This is the bottom and top frames so we have to make them thinner in width and larger in height
	hairs.top.Size = UDim2.fromOffset(self.thickness, self.size)
	hairs.bottom.Size = UDim2.fromOffset(self.thickness, self.size)

    -- update color and outline
    for i, v in pairs(hairs) do
        v = v :: Frame
        v.BackgroundColor3 = Color3.new(self.red, self.green, self.blue)
        v.BorderSizePixel = self.outline and 1 or 0
    end

end

function crosshair:enable()
    for i, v in pairs(self.hairs) do
        v.Visible = true
    end
end

function crosshair:disable()
    for i, v in pairs(self.hairs) do
        v.Visible = false
    end
end

function crosshair:connect()
    self.connection = RunService.RenderStepped:Connect(function()

        -- update when resolution is changed
        if self.hud.AbsoluteSize ~= self.resolution then
            self.resolution = self.hud.AbsoluteSize
            self:updateCrosshair()
        end

    end)
end

return crosshair
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData)

local Crosshair = {}

function Crosshair.init(hudClass, hudGui)
    local self = Crosshair
    self.hudClass = hudClass
    self.hud = hudGui
    self.resolution = self.hud.AbsoluteSize
    self.origin = UDim2.fromOffset(self.resolution.X / 2, self.resolution.Y / 2)
    self.hairs = {}
    self.player = game.Players.LocalPlayer

    -- this is a brute force way to get client stored player data
    -- alternatively, you could use module:Get() or module:GetAsync()
    --[[local clientPlayerDataModule = require(ReplicatedStorage.PlayerData.m_clientPlayerData)
	if not clientPlayerDataModule.stored then repeat task.wait() until clientPlayerDataModule.stored end
    self.clientModule = clientPlayerDataModule]]

    self.storedOptions = PlayerData:GetPath(self.player, "options.crosshair")

    if self.hud:FindFirstChild("Crosshair") then
        self.hud.Crosshair:Destroy()
    end

    self.crosshairgui = Instance.new("ScreenGui")
    self.crosshairgui.IgnoreGuiInset = true
    self.crosshairgui.Name = "Crosshair"
    self.crosshairgui.Parent = self.hud
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
    Crosshair = self
    return self
end

return Crosshair
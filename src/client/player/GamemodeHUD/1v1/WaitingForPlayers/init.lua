local WFP = {}
WFP.__index = WFP
local Gui = script:WaitForChild("Gui")

function WFP.init()
    local self = setmetatable({}, WFP)
    self.gui = Gui:Clone()
    self.gui.Parent = game.Players.LocalPlayer.PlayerGui
    return self
end

function WFP:Disable()
    -- play tween animation here
    self.gui:Destroy()
    self = nil
end

function WFP:Destroy()
    self:Disable()
end

return WFP
local Component = {}
Component.__index = Component

function Component.new(hudClass, module)
    local self = setmetatable(require(module), Component)
    self.hudClass = hudClass
    self.hud = hudClass.gui
    self.player = game.Players.LocalPlayer
    self.connections = {}
    self.gui = false -- define gui in Component.init
    self:init()
    return self
end

function Component:init()
    self.gui = Instance.new("Frame", self.hud)
end

function Component:Enable()
    self.gui.Visible = true
    self:Connect()
end

function Component:Disable()
    self.gui.Visible = false
    self:Disconnect()
end

function Component:Connect()
    
end

function Component:Disconnect()
    
end

return Component
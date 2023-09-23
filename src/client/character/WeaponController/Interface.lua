local ReplicatedStorage = game:GetService("ReplicatedStorage")
local interface = {}
interface.currentController = nil

local init = Instance.new("BindableEvent", ReplicatedStorage)
interface.Event = init.Event

function interface.init(controller)
    interface.currentController = controller
    interface.__index = controller
    init:Fire()
end

return interface
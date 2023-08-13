--[[
	Init
]]

local viewmodelModule = require(script.Parent.m_viewmodel):initialize()

--[[
	Connections
]]

viewmodelModule.hum.Died:Connect(function()
    viewmodelModule:destroy()
end)

--[[todo: change events to module functions]]
--[[script:WaitForChild("Jump").Event:Connect(function()
	--jumpSway(cdt)
end)]]
--script:WaitForChild("ConnectVMSpring").Event:Connect(viewmodelModule:)
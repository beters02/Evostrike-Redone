local viewmodelModule = require(script:WaitForChild("m_viewmodel")):initialize()

viewmodelModule.hum.Died:Connect(function()
    viewmodelModule:destroy()
end)
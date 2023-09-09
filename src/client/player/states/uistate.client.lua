-- responsible for handling UI state properties
-- ex: if a UI is enabled in which the MouseIcon is enabled with, the MouseIcon stays enabled

local UserInputService = game:GetService("UserInputService")
local States = require(game:GetService("ReplicatedStorage"):WaitForChild("states"):WaitForChild("m_states"))
local UIState = States.State("UI")

-- Connect Mouse Icon Update
UIState:changed(function()
    UserInputService.MouseIconEnabled = UIState:shouldMouseBeEnabled()
end)
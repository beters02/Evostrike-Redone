task.wait(2)

local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local TweenService = game:GetService("TweenService")
local Playerdata = require(Framework.shm_clientPlayerData.Location)

-- initial
local deffov = Playerdata:Get("options.camera.FOV")

-- smoothen out fov transfer if necessary
local function smooth(newFov)
    TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {FieldOfView = newFov}):Play()
end

if workspace.CurrentCamera.FieldOfView ~= deffov then
    smooth(deffov)
end

-- FOV changed
local fovChangeConn = Playerdata:Changed("options.camera.FOV", function(newValue)
    deffov = newValue
    smooth(deffov)
end)
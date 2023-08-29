local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local instance = require(Framework.shfc_instance.Location)
local CastVisuals = require(Framework.shfc_castvisuals.Location)

local CastVisualizer = CastVisuals.new(Color3.fromRGB(255,0,0), workspace)

print(CastVisuals)

local module = {}
module._storedMovementConfig = false

-- Init Movement Var on Init
function module.GetMovementVar()
    if RunService:IsServer() then
        return require(game:GetService("ServerScriptService"):WaitForChild("movement").config.main)
    else
        -- This will be haneled in server.movement.get
        return ReplicatedStorage.movement.get:InvokeServer()
    end
end

function module.IsGrounded(player)

	local params = instance.New("RaycastParams", {
		FilterType = Enum.RaycastFilterType.Exclude,
		FilterDescendantsInstances = {player.Character, RunService:IsClient() and workspace.CurrentCamera or {}},
		CollisionGroup = "PlayerMovement"
	})

	local result = workspace:Blockcast(
		CFrame.new(player.Character.HumanoidRootPart.CFrame.Position + Vector3.new(0, -3.25, 0)),
		Vector3.new(1.5,1.5,1),
		Vector3.new(0, -1, 0),
		params
	)

	--[[CastVisualizer:Blockcast(
		CFrame.new(player.Character.HumanoidRootPart.CFrame.Position + Vector3.new(0, -3.25, 0)),
		Vector3.new(1.5,1.5,1),
		Vector3.new(0, -1, 0),
		params
	)]]

	if result then
		return result.Instance, result.Position, result.Normal, result.Material
	end

	return false
end

function module.GetIgnoreDescendantInstances(player)
	return {player.Character, workspace.CurrentCamera, workspace.Temp, workspace.MovementIgnore}
end

-- does not replicate mut
-- For things like friction, ground accel/decel, etc you will NOT want to trust this config.
module._storedMovementConfig = module.GetMovementVar()
module._storedMovementConfig.rayYLength = module._storedMovementConfig.playerTorsoToGround + module._storedMovementConfig.movementStickDistance

return module
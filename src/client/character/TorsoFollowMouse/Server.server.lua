local character = script.Parent.Parent
local head = character:WaitForChild("Head")
local neck = head:WaitForChild("Neck")
local remote = script.Parent.Remote
local toClientRemote = game.ReplicatedStorage.TorsoFollowMouse.ToClientRemote

neck.MaxVelocity = 1/3

local function UpdateVariables(player, point, torsoLookVector, cameraLookVector, neckOriginC0, waistOriginC0, lShoulderC0, rShoulderC0)
    toClientRemote:FireAllClients(player, point, torsoLookVector, cameraLookVector, neckOriginC0, waistOriginC0, lShoulderC0, rShoulderC0)
end

remote.OnServerEvent:Connect(UpdateVariables)
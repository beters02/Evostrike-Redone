local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local shared = require(script.Parent:WaitForChild("Shared"))
local update_rate = shared.update_rate
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local cam = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")
local neck = head:WaitForChild("Neck")
local torso = character:WaitForChild("UpperTorso")
local waist = torso:WaitForChild("Waist")
local rShoulder = character.RightUpperArm.RightShoulder
local lShoulder = character.LeftUpperArm.LeftShoulder
local localRemote = script.Parent:WaitForChild("Remote")
local clientToClientRemote = game.ReplicatedStorage.TorsoFollowMouse.ToClientRemote
local neckOriginC0 = neck.C0
local waistOriginC0 = waist.C0
local rShoulderC0 = rShoulder.C0
local lShoulderC0 = lShoulder.C0
neck.MaxVelocity = 1/3

--@title 		Player Packet Storage
--@summary 		All Player Torso Movement CFrames are stored as "Packets" which are tables that contain
--				the necessary vectors and CFrames needed to complete the Torso Rotation.
--
--				Is this more complicated than it has to be? Yes. I had fun though
local StoredPackets = {} :: shared.PacketStorage

local function getPoint()
	local mray = cam:ViewportPointToRay(mouse.X, mouse.Y, 1337)
	return mray.Origin + mray.Direction
end

local function isCamOnChar()
	return cam.CameraSubject:IsDescendantOf(character) or cam.CameraSubject:IsDescendantOf(player)
end

local function hasRequiredParts()
	return (neck and waist and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Head"))) and true or false
end

local function updateYourTorsoVar()
	if not character or not character.Humanoid or character.Humanoid.Health <= 0 then return end
	if isCamOnChar() and hasRequiredParts() then
		localRemote:FireServer(getPoint(), torso.CFrame.LookVector, cam.CFrame.LookVector, neckOriginC0, waistOriginC0, lShoulderC0, rShoulderC0) -- send variables off to have Packets created when receieved.
	end
end

local function fulfillUpdateOtherTorsoVar(...)
	local _movePlayer = ... -- the rest of the packet is contained in ..., the first variable is _movePlayer
	StoredPackets[_movePlayer.Name] = shared.Packet.new(...)
end

local function GetThetaAngles(mult, packet: shared.Packet)
	return CFrame.Angles(-(math.atan(packet.difference / packet.distance) * 0.5), (((packet.headpos - packet.point).Unit):Cross(packet.torsoLV)).Y * mult, 0)
end

RunService.RenderStepped:Connect(function()
	for _, plr in pairs(Players:GetPlayers()) do
		pcall(function()
			local packet = (plr.Character and plr.Character.Humanoid.Health > 0) and StoredPackets[plr.Name]
			if packet then
				local _mNeck = 	plr.Character.Head.Neck
				local _mWaist = plr.Character.UpperTorso.Waist
				local _mR = 	plr.Character.RightUpperArm.RightShoulder
				local _mL = 	plr.Character.LeftUpperArm.LeftShoulder

				_mNeck.C0 = 	_mNeck.C0:lerp(packet.neckC0 * GetThetaAngles(1, packet), 0.5 / 2)
				_mWaist.C0 = 	_mWaist.C0:lerp(packet.waistC0 * GetThetaAngles(0.5, packet), 0.5 / 2)
				_mR.C0 = 		_mR.C0:lerp(packet.rightShoulderC0 * GetThetaAngles(0.5, packet), 0)
				_mL.C0 = 		_mL.C0:lerp(packet.leftShoulderCO * GetThetaAngles(0.5, packet), 0)
			end
		end)
	end
end)

clientToClientRemote.OnClientEvent:Connect(fulfillUpdateOtherTorsoVar)

while true do
	task.wait(update_rate)
	updateYourTorsoVar()
end
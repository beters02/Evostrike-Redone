export type OriginCFrame = CFrame
export type LookVector = Vector3
export type PlayerName = string
export type PacketStorage = {PlayerName: Packet}
export type Packet = {
    point: Vector3,
    distance: Vector3,
    difference: number,
    headpos: Vector3,
    torsoLV: LookVector,
    cameraLV: LookVector,
    neckC0: OriginCFrame,
    waistC0: OriginCFrame,
    rightShoulderC0: OriginCFrame,
    leftShoulderCO: OriginCFrame,
}

--

local shared = {}
shared.update_rate = 1/12

-- [[ Packets ]]

local Packet = {}
Packet.__index = Packet

function Packet.new(_movePlayer, point, torsoLookVector, cameraLookVector, _neckOriginC0, _waistOriginC0, _lShoulderC0, _rShoulderC0)
	if not _movePlayer.Character then return end
	local packet: Packet = {
		point = point,
		distance = (_movePlayer.Character.Head.CFrame.Position - point).Magnitude,
		difference = _movePlayer.Character.Head.CFrame.Y - point.Y,
        headpos = _movePlayer.Character.Head.CFrame.Position,
		torsoLV = torsoLookVector,
		cameraLV = cameraLookVector,
		neckC0 = _neckOriginC0,
		waistC0 = _waistOriginC0,
		leftShoulderCO = _lShoulderC0,
		rightShoulderC0 = _rShoulderC0
	}
	return packet
end

--

shared.Packet = Packet
return shared
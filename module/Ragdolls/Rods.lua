--[[ ** WIP Ragdolls W/ Rod Constraints **

type rodTable = {
	lRod: RodConstraint,
	rRod: RodConstraint,
	ltop: Attachment,
	rtop: Attachment,
	lbottom: Attachment,
	rbottom:Attachment
}
local rodTable = {}

--@summary Generate a new rodTable
function rodTable.new()
	local self = {
		lRod = Instance.new("RodConstraint"),
		rRod = Instance.new("RodConstraint"),
		ltop = Instance.new("Attachment"),
		rtop = Instance.new("Attachment"),
		lbottom = Instance.new("Attachment"),
		rbottom = Instance.new("Attachment")
	}
	self.lRod.Visible = true
	self.rRod.Visible = true
	return self
end

function initRod()
	--[[local _pos = part0.CFrame.Position
	local _size = part0.Size
	if v.Parent.Name == "RightUpperArm" then
		initPartTopRodPos(v.Parent, _pos, _size, rRods)
	elseif v.Parent.Name == "LeftUpperArm" then
		initPartTopRodPos(v.Parent, _pos, _size, lRods)
	elseif v.Parent.Name == "RightLowerArm" then
		initPartBottomRodPos(v.Parent, _pos, _size, rRods)
	elseif v.Parent.Name == "LeftLowerArm" then
		initPartBottomRodPos(v.Parent, _pos, _size, lRods)
	end
end

function initPartTopRodPos(part, pos, size, rods)
	rods.lRod.Parent = part
	rods.rRod.Parent = part
	rods.ltop.Parent = part
	rods.rtop.Parent = part
	rods.rtop.CFrame = CFrame.new(Vector3.new(pos.X - (size.X/2), pos.Y + (size.Y/2), pos.Z)) -- move rrod attatchment to the top right corner
	rods.ltop.CFrame = CFrame.new(Vector3.new(pos.X + (size.X/2), pos.Y + (size.Y/2), pos.Z)) -- move lrod attatchment to the top left corner
end

function initPartBottomRodPos(part, pos, size, rods)
	rods.lbottom.Parent = part
	rods.rbottom.Parent = part
	rods.rbottom.CFrame = CFrame.new(Vector3.new(pos.X - (size.X/2), pos.Y - (size.Y/2), pos.Z)) -- move rrod attatchment to the bottom right corner
	rods.lbottom.CFrame = CFrame.new(Vector3.new(pos.X + (size.X/2), pos.Y - (size.Y/2), pos.Z)) -- move lrod attatchment to the bottom left corner
end

function finalizeRods(lRods: rodTable, rRods: rodTable)
	for _, rods in ipairs({lRods, rRods}) do
		rods.lRod.Attachment0 = rods.ltop
		rods.lRod.Attachment1 = rods.lbottom
		rods.rRod.Attachment0 = rods.rtop
		rods.rRod.Attachment1 = rods.rbottom
	end
end

]]
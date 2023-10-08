local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local WeaponServiceAssets = ReplicatedStorage.Services.WeaponService.ServiceAssets
local BulletModel = WeaponServiceAssets.Models:WaitForChild("Bullet")
local BulletHole = WeaponServiceAssets.Models:WaitForChild("BulletHole")
local EmitParticle = require(ReplicatedStorage.lib.fc_emitparticle)

local Shared = {
    WallbangMaterials = {
        LightMetal = 0.7,
        HeavyMetal = 0.4,
        LightWood = 0.85,
        HeavyWood = 0.5
    }
}

function Shared.CreateBulletHole(result)
	if not result then return end

	local normal = result.Normal
	local cFrame = CFrame.new(result.Position, result.Position + normal)
	local bullet_hole = BulletHole:Clone()
	bullet_hole.CFrame = cFrame
	bullet_hole.Anchored = true
	bullet_hole.CanCollide = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bullet_hole
	weld.Part1 = result.Instance
	weld.Parent = bullet_hole
	bullet_hole.Parent = workspace.Temp

	local isBangable = false
	local _succ = pcall(function()
		isBangable = result.IsBangableWall
	end)
	isBangable = _succ and isBangable or false
	
    EmitParticle.EmitParticles(result.Instance, EmitParticle.GetBulletParticlesFromInstance(result.Instance), bullet_hole, nil, nil, nil, isBangable)
	
	Debris:AddItem(bullet_hole, 8)
	return bullet_hole
end

function Shared.CreateBullet(tool, endPos, client, fromModel)

	--create bullet part
	local part = BulletModel:Clone()

	local pos
	if fromModel then
		pos = fromModel.GunComponents.WeaponHandle.FirePoint.WorldPosition
	else
		pos = tool.ServerModel.GunComponents.WeaponHandle.FirePoint.WorldPosition
	end

	part.Size = Vector3.new(0.1, 0.1, 0.4)
	part.Position = pos
	part.CFrame = CFrame.new(pos)
	part.Transparency = 1
	part.CFrame = CFrame.lookAt(pos, endPos)
	part.CollisionGroup = "None"
	part.Parent = workspace.Temp

	local tween = TweenService:Create(
		part,
		TweenInfo.new(((pos - endPos).magnitude) * (1 / 900)), -- 900 studs a sec
		{Position = endPos}
	)

	-- create finished event to fire
	local finished = Instance.new("BindableEvent")

	task.wait()

	tween:Play() -- play tweens and destroy bullet
	tween.Completed:Wait()

	-- we anchor and then let the trails finish
	part.Anchored = true
	part.Transparency = 1
	Debris:AddItem(part, 3)

	-- fire finished event
	finished:Fire()
	Debris:AddItem(finished, 3)

	return part, finished
end

return Shared
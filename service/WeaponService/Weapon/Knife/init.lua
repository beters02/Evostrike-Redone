local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local States = require(Framework.Module.States)
local Math = require(Framework.Module.lib.fc_math)
local RaycastHitbox = require(Framework.Module.lib.c_raycasthitbox)

export type AttackType = "Primary" | "Secondary"

local Knife = {}
Knife.Configuration = {
	name = "knife",
	inventorySlot = "ternary",
	automatic = false,

	-- model = secondToSkipTo
	inspectAnimationTimeSkip = {
		default = 0.03,
		karambit = 0.225,
		m9bayonet = 0.1
	},

	damageCastLength = 7,
	
	totalAmmoSize = 90,
	magazineSize = 30,
	
	equipLength = 1,
	fireRate = 0.325,
	secondaryFireRate = 0.75,
	reloadLength = 1.5,
	recoilReset = 0.3,
	
	fireVectorCameraOffset = Vector2.new(10, 10),
	fireVectorCameraMax = Vector3.new(0.008, 0.007, 0.1),
	
	fireVectorSpring = {
		speed = 50,
		damp = 1,
		downWait = 0.07,
		max = 0.1
	},
	
	accuracy = {base = 1},
	
	damage = {
		base = 27.5,
		secondary = 50,
		headMultiplier = 1.5,
		primaryBackstab = 75,
		secondaryBackstab = 150,
	},

	movement = {
		penalty = 0,
		hitTagAmount = 6
	}
}

function Knife:init()
	self.RaycastHitbox = RaycastHitbox.new(self.ClientModel:FindFirstChild("Blade") or self.ClientModel)
    self.RaycastHitbox.Visualizer = false
    self.RaycastHitbox:SetPoints(self.ClientModel.GunComponents.WeaponHandle, {Vector3.new(1, 0, 0), Vector3.new(5, 0, 0), Vector3.new(10, 0, 0)})
    self.Variables.KnifeParams = RaycastParams.new()
    self.Variables.KnifeParams.CollisionGroup = "Bullets"
    self.Variables.KnifeParams.FilterDescendantsInstances = {self.Character, workspace.CurrentCamera}
    self.Variables.KnifeParams.FilterType = Enum.RaycastFilterType.Exclude
end

--@override
function Knife:PrimaryFire()
	self:Fire("Primary")
end

--@override
function Knife:SecondaryFire()
	self:Fire("Secondary")
end

--@override
function Knife:Reload()
	return
end

-- Called when Primary/Secondary Fire
function Knife:Fire(AttackType: AttackType)
	if not self.Variables.equipped and self.Variables.equipping then return end
	if self.Variables.firing then return end
	self.Variables.firing = true
	States:Get("PlayerActions"):set("shooting", true)

	-- damage, animations, sounds
	task.spawn(function() self:Attack(AttackType) end)

	-- fire rate
	local nextFire = tick() + (AttackType == "Primary" and self.Options.fireRate or self.Options.secondaryFireRate)
	task.spawn(function()
		repeat task.wait() until tick() >= nextFire
		self.Variables.firing = false
		States:Get("PlayerActions"):set("shooting", false)
	end)
end

-- Called after Fire
function Knife:Attack(attackType: AttackType)
	attackType = attackType or "Primary"

	local player = Players.LocalPlayer
	local mos = player:GetMouse()
	local mosRay = workspace.CurrentCamera:ScreenPointToRay(mos.X, mos.Y)

	self:PlayReplicatedSound(attackType .. "Attack")

	-- initial knife "stab" cast by casting a short ray to see if player is looking at a bodypart they can stab
	local stabResult = workspace:Raycast(mosRay.Origin, mosRay.Direction * self.Options.damageCastLength, self.Variables.KnifeParams)
	if stabResult then
		local hum = _hitIsHum(stabResult.Instance)
		if hum then
			self:PlayReplicatedSound(attackType .. "Stab")
			if Math.normalToFace(stabResult.Normal, stabResult.Instance) == Enum.NormalId.Back
			and (string.match(stabResult.Instance.Name, "Torso") or string.match(stabResult.Instance.Name, "RootPart")) then -- client registered backstab!
				self:PlayAnimation("client", attackType .. "Stab", true) -- play primary/secondary backstab animation
				self.RemoteEvent:FireServer("VerifyKnifeDamage", attackType .. "Stab", hum)
			else
				self:PlayAnimation("client", (attackType or "Primary") .. "Attack", true)  -- just play slash animation & slash hit sound
				self.RemoteEvent:FireServer("VerifyKnifeDamage", attackType, hum)
			end
			return
		end
	end

	-- play slash animation here
	self:PlayAnimation("client", (attackType or "Primary") .. "Attack", true)

	-- connect "slash" result
	local damaged = false
	local enabled = true
	self.Connections._knifeDamageConnection = self.RaycastHitbox.OnHit:Connect(function(hit, humanoid)
		if not damaged and humanoid then
			if humanoid then
				damaged = true
				self:PlayReplicatedSound(attackType .. "Stab")
				self.RemoteEvent:FireServer("VerifyKnifeDamage", attackType, humanoid)
				if enabled then
					enabled = false
					self.RaycastHitbox:HitStop()
				end
				self.Connections._knifeDamageConnection:Disconnect()
			end
		end
	end)

	-- enable slash hitbox
	self.RaycastHitbox:HitStart()
	task.delay((attackType == "Primary" and self.Options.fireRate or self.Options.secondaryFireRate) * 0.75, function()
		if enabled then
			enabled = false
			self.RaycastHitbox:HitStop()
		end
	end)
end

--@summary Check if the hit instance is a humanoid
function _hitIsHum(instance)
	return instance.Parent:FindFirstChild("Humanoid") or instance.Parent.Parent:FindFirstChild("Humanoid") or false
end

Knife.sprayPattern = "Melee"
return Knife
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local States = require(Framework.shm_states.Location)
local Math = require(Framework.Module.lib.fc_math)
local RaycastHitbox = require(Framework.Module.lib.c_raycasthitbox)

local core = {knife = true}
core.__index = core

-- _[2] = player
function core.fire(self, _, weaponOptions, weaponVar)
	if weaponVar.firing then return weaponVar end
	weaponVar.firing = true
	States.SetStateVariable("PlayerActions", "shooting", true)

	-- damage, animations, sounds
	task.spawn(function()
		weaponVar = _knifeAttack(self, "Primary", weaponOptions, weaponVar)
	end)

	local nextFire = tick() + weaponOptions.fireRate -- fire rate
	task.spawn(function()
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
		States.SetStateVariable("PlayerActions", "shooting", false)
	end)

	return weaponVar
end

function core.secondaryFire(self, _, weaponOptions, weaponVar)
	if weaponVar.firing then return weaponVar end
	weaponVar.firing = true
	States.SetStateVariable("PlayerActions", "shooting", true)

	-- damage, animations, sounds
	task.spawn(function()
		weaponVar = _knifeAttack(self, "Secondary", weaponOptions, weaponVar)
	end)
	

	local nextFire = tick() + weaponOptions.secondaryFireRate -- fire rate
	task.spawn(function()
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
		States.SetStateVariable("PlayerActions", "shooting", false)
	end)

	return weaponVar
end

-- self, weaponOptions, weaponVar, weaponRemoteFunction
function core.reload(_, _, weaponVar, _)
	return weaponVar
end

--

function _hitIsHum(instance)
	return instance.Parent:FindFirstChild("Humanoid") or instance.Parent.Parent:FindFirstChild("Humanoid") or false
end

function _knifeAttack(coreself, attackType: "Primary" | "Secondary"?, weaponOptions, weaponVar)
	attackType = attackType or "Primary"

	local player = Players.LocalPlayer
	local mos = player:GetMouse()
	local mosRay = workspace.CurrentCamera:ScreenPointToRay(mos.X, mos.Y)

	coreself.animationEventFunctions.PlayReplicatedSound(attackType .. "Attack")

	-- initial knife "stab" cast by casting a short ray to see if player is looking at a bodypart they can stab
	local stabResult = workspace:Raycast(mosRay.Origin, mosRay.Direction * weaponOptions.damageCastLength, weaponVar._knifeParams)
	if stabResult then
		local hum = _hitIsHum(stabResult.Instance)
		if hum then
			coreself.animationEventFunctions.PlayReplicatedSound(attackType .. "Stab")
			if Math.normalToFace(stabResult.Normal, stabResult.Instance) == Enum.NormalId.Back
			and (string.match(stabResult.Instance.Name, "Torso") or string.match(stabResult.Instance.Name, "RootPart")) then -- client registered backstab!
				coreself.util_playAnimation("client", attackType .. "Stab", false, true) -- play primary/secondary backstab animation
				coreself.remoteEvent:FireServer("VerifyKnifeDamage", attackType .. "Stab", hum)
			else
				coreself.util_playAnimation("client", (attackType or "Primary") .. "Attack", false, true)  -- just play slash animation & slash hit sound
				coreself.remoteEvent:FireServer("VerifyKnifeDamage", attackType, hum)
			end

			return weaponVar
		end
	end

	-- play slash animation here
	coreself.util_playAnimation("client", (attackType or "Primary") .. "Attack", false, true)

	-- connect "slash" result
	local damaged = false
	local enabled = true
	weaponVar._knifeDamageConnection = weaponVar._raycastHitbox.OnHit:Connect(function(hit, humanoid)
		if not damaged and humanoid then
			if humanoid then
				damaged = true
				coreself.animationEventFunctions.PlayReplicatedSound(attackType .. "Stab")
				coreself.remoteEvent:FireServer("VerifyKnifeDamage", attackType, humanoid)
				if enabled then
					enabled = false
					weaponVar._raycastHitbox:HitStop()
				end
				weaponVar._knifeDamageConnection:Disconnect()
			end
		end
	end)

	-- enable slash hitbox
	weaponVar._raycastHitbox:HitStart()
	task.delay((attackType == "Primary" and weaponOptions.fireRate or weaponOptions.secondaryFireRate) * 0.75, function()
		if enabled then
			enabled = false
			weaponVar._raycastHitbox:HitStop()
		end
	end)

	return weaponVar
end

return core
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local States = require(Framework.shm_states.Location)
local SharedWeaponFunctions = require(Framework.shfc_sharedWeaponFunctions.Location)

local core = {}
core.__index = core

--[[@title 			- core_fire
	@return			- {void}
]]

local last = tick()

-- _[1] = player, _[2] = startTick
function core.fire(self, _, weaponOptions, weaponVar, weaponCameraObject, animationEventFunctions, _)
	--task.spawn(function() self.core_stopInspecting(0.05) end)

    -- set var
	States.SetStateVariable("PlayerActions", "shooting", true)

	local t = tick()
	weaponVar.firing = true
	weaponVar.ammo.magazine -= 1
	weaponVar.currentBullet = (t - weaponVar.lastFireTime >= weaponOptions.recoilReset and 1 or weaponVar.currentBullet + 1)
	weaponVar.lastFireTime = t
	weaponCameraObject.weaponVar.currentBullet = weaponVar.currentBullet

	-- Play Emitters and Sounds
	task.spawn(function()
		animationEventFunctions.PlayReplicatedSound("Fire", true)
		SharedWeaponFunctions.ReplicateFireEmitters(weaponVar.serverModel, weaponVar.clientModel)
	end)

	-- Create Visual Bullet, Register Camera & Vector Recoil, Register Accuracy & fire to server
	self.util_RegisterRecoils()

	-- play animations
	self.util_playAnimation("client", "Fire", false, true)
    weaponVar.animations.server.Fire:Play()
	
	-- handle client fire rate & auto reload
	local nextFire = t + weaponOptions.fireRate
	task.spawn(function()
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
		States.SetStateVariable("PlayerActions", "shooting", false)
	end)

	-- update hud
	weaponVar.infoFrame.CurrentMagLabel.Text = tostring(weaponVar.ammo.magazine)

	-- send to auto reload im assuming
	if weaponVar.ammo.magazine <= 0 and weaponVar.equipped then
		return weaponVar, nextFire
	end

	-- return weaponVar since we updated ammo
	return weaponVar
end

--[[@title 			- core_reload
	@return			- {void}
]]

function core.reload(self, weaponOptions, weaponVar, weaponRemoteFunction)
	if weaponVar.ammo.total <= 0 or weaponVar.ammo.magazine == weaponOptions.ammo.magazine then return weaponVar end
	if weaponVar.firing or weaponVar.reloading or not weaponVar.equipped then return weaponVar end
	
	States.SetStateVariable("PlayerActions", "reloading", true)
	
	task.spawn(function()
		self.util_playAnimation("client", "Reload", false, true)
		--weaponVar.animations.server.Reload:Play() TODO: make server reload animations
	end)

	weaponVar.reloading = true

	local mag, total = weaponRemoteFunction:InvokeServer("Reload")
	weaponVar.ammo.magazine = mag
	weaponVar.ammo.total = total

	-- update hud
	weaponVar.infoFrame.CurrentMagLabel.Text = tostring(mag)
	weaponVar.infoFrame.CurrentTotalAmmoLabel.Text = tostring(total)

	weaponVar.reloading = false
	States.SetStateVariable("PlayerActions", "reloading", false)

	return weaponVar
end

return core
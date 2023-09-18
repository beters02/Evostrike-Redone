local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local States = require(Framework.shm_states.Location)
local SharedWeaponFunctions = require(Framework.shfc_sharedWeaponFunctions.Location)

local core = {}
core.__index = core

--[[@title 			- core_fire
	@return			- {void}
]]

local last = tick()

function core.fire(self, player, weaponOptions, weaponVar, weaponCameraObject, animationEventFunctions, startTick)

	task.spawn(function() self.core_stopInspecting(0.05) end)

	last = tick()

    local mouse = player:GetMouse()

    -- set var
	States.SetStateVariable("PlayerActions", "shooting", true)
	local t = tick()
	local mosPos = Vector2.new(mouse.X, mouse.Y)
	local fireRegisterTime = workspace:GetServerTimeNow()
	--weaponVar.fireLoop = true
	weaponVar.firing = true
	--weaponVar.nextFireTime = t + weaponOptions.fireRate
	weaponVar.ammo.magazine -= 1
	weaponVar.currentBullet = (t - weaponVar.lastFireTime >= weaponOptions.recoilReset and 1 or weaponVar.currentBullet + 1)
	weaponVar.lastFireTime = t
	weaponCameraObject.weaponVar.currentBullet = weaponVar.currentBullet

	-- Play Emitters
	task.spawn(function()
		SharedWeaponFunctions.ReplicateFireEmitters(weaponVar.serverModel, weaponVar.clientModel)
	end)

	-- Create Visual Bullet, Register Camera & Vector Recoil, Register Accuracy & fire to server
	self.util_RegisterRecoils()

	-- play animations
	self.util_playAnimation("client", "Fire")
    weaponVar.animations.server.Fire:Play()

	-- play sounds
	task.spawn(function()
		animationEventFunctions.PlayReplicatedSound("Fire", true)
	end)
	
	-- handle client fire rate & auto reload
	local nextFire = t + weaponOptions.fireRate
	task.spawn(function()
		repeat task.wait() until tick() >= nextFire
		weaponVar.firing = false
		States.SetStateVariable("PlayerActions", "shooting", false)
	end)

	-- update hud
	weaponVar.infoFrame.CurrentMagLabel.Text = tostring(weaponVar.ammo.magazine)

	if weaponVar.ammo.magazine <= 0 and weaponVar.equipped then
		return weaponVar, nextFire
	end

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
		self.core_stopInspecting(0.05)
		weaponVar.animations.client.Reload:Play()
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
local core = {knife = true}
core.__index = core

function core.fire(self, player, weaponOptions, weaponVar)
	-- play animations
	self.util_playAnimation("client", "PrimaryAttack")
	return weaponVar
end

function core.reload(self, weaponOptions, weaponVar, weaponRemoteFunction)
	return weaponVar
end

return core
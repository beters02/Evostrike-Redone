local core = {knife = true}
core.__index = core

function core.fire(self, player, weaponOptions, weaponVar)
	-- play animations
	self.util_playAnimation("client", "Fire")
	return weaponVar
end

function core.reload(weaponOptions, weaponVar, weaponRemoteFunction)
	return weaponVar
end

return core
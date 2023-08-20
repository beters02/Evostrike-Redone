local core = {knife = true}
core.__index = core

function core.fire(self)
	print('worked')
	-- play animations
	self.util_playAnimation("client", "Fire")
	
end

return core
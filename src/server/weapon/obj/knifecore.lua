local core = {knife = true}
core.__index = core

function core.fire(self)
	-- play animations
	self.util_playAnimation("client", "Fire")
end

function core.reload()
	return
end

return core
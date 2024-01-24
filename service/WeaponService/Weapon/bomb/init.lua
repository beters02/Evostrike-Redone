local Bomb = {}
Bomb.Configuration = {}

--@override
function Bomb:PrimaryFire()
	self:Plant()
end

--@override
function Bomb:SecondaryFire()
	self:Plant()
end

--@override
function Bomb:Reload()
	return
end

-- Called when Primary/Secondary Fire
function Bomb:Plant()
	if not self.Variables.equipped and self.Variables.equipping then return end
	if self.Variables.firing then return end
	self.Variables.firing = true

    -- check if player is in planting radius

    
end

return Bomb
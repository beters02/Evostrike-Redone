local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Particles = ReplicatedStorage:WaitForChild("Assets").Particles
local module = {}

local function darkenColor(co)
	local _c = {}
	for i, v in pairs({R = co.R, G = co.G, B = co.B}) do
		_c[i] = v * 0.8
	end
	return Color3.fromRGB(_c.R, _c.G, _c.B)
end

function module.Emit(instance, particle, emitParent, char, emitAmount, lifetime, isBangableWall)

	-- create clone
	local c = particle:Clone()
	local parent = emitParent or instance
	
	if char and char:FindFirstChild("RagdollValue") then
		parent = char.RagdollValue.Value[instance.Name]
	end
	c.Parent = parent

	-- color
	local co = c:FindFirstChild("PartColor")
	if co and co.Value then
		co = instance.Color
	elseif c:FindFirstChild("ColorValue") then
		co = c.ColorValue.Value
	else
		co = false
	end

	-- if we can wallbang we want to make the color of the particles slightly darker
	if isBangableWall then
		if not co then
			local newColor = Color3.new(0.509804, 0.396078, 0.113725)
			co = ColorSequence.new(newColor)
		elseif typeof(co) == "Color3" then
			co = darkenColor(co)
			co = ColorSequence.new(co)
		end
	end

	if typeof(co) == "ColorSequence" then
		c.Color = co
	end

	-- emit
	local emitCount = emitAmount or (c:FindFirstChild("EmitCount") and c.EmitCount.Value) or 1
	c:Emit(emitCount)
	Debris:AddItem(c, 5)
	
	return c
end

--@summary Emit particles.
--		   Supply a Vector3 for "emitParent" and it will make it's own part to emit out of at the Vector3 Position provided.
function module.EmitParticles(instance, particles, emitParent, char, emitAmount, lifetime, isBangableWall)
	if typeof(emitParent) == "Vector3" then
		local pos = emitParent
		emitParent = Instance.new("Part")
		emitParent.Size = Vector3.new(0.7,0.7,0.7)
		emitParent.CFrame = CFrame.new(pos)
		emitParent.Transparency = 1
		emitParent.Anchored = true
		emitParent.Parent = workspace.Temp
		Debris:AddItem(emitParent, 8)
	end
	local clones = {}
	for i, v in pairs(particles) do
		module.Emit(instance, v, emitParent, char, emitAmount, lifetime, isBangableWall)
	end
	return clones
end

function module.GetBulletParticlesFromInstance(instance)
	local particles = {}
	local mat = tostring(instance.Material):gsub("Enum.Material.", "")
	local folder = Particles.GunVisualEffects.Common.HitEffect:FindFirstChild(mat)
	if folder then
		for i, v in pairs(folder:GetChildren()) do
			table.insert(particles, v)
		end
		if #particles >= 1 then
			return particles
		else
			error("Could not find particles for matfolder " .. mat)
		end
	end
	error("Could not find matfolder for " .. mat)
	return false
end

function module.GetParticles()
	local ParticlesTable = {}

	local function recurseAddParticleFolderDescendants(tab)
		for _, v in pairs(tab) do
			if v:IsA("ParticleEmitter") then
				ParticlesTable[v.Parent.Name .. "." .. v.Name] = v
			elseif v:IsA("Folder") then
				recurseAddParticleFolderDescendants(v:GetDescendants())
			end
		end
	end

	recurseAddParticleFolderDescendants(Particles:GetDescendants())
	
	return ParticlesTable
end

return module

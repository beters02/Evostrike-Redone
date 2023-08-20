local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Particles = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("obj"):WaitForChild("particles")
local module = {}

function module.Emit(instance, particle, emitParent, char, emitAmount, lifetime)
	
	-- create clone
	local c = particle:Clone()
	local parent = emitParent or instance
	
	if char and char:FindFirstChild("RagdollValue") then
		parent = char.RagdollValue.Value[instance.Name]
	end
	c.Parent = parent

	-- color
	local co = c:FindFirstChild("PartColor")
	if co then
		c.Color = ColorSequence.new(instance.Color)
	end

	-- emit
	local emitCount = emitAmount or (c:FindFirstChild("EmitCount") and c.EmitCount.Value) or 1
	c:Emit(emitCount)
	
	--print('emitted ' .. tostring(emitCount) .. " " .. tostring(instance))
	return c
end

function module.EmitParticles(instance, particles, ...)
	local clones = {}
	for i, v in pairs(particles) do
		module.Emit(instance, v, ...)
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

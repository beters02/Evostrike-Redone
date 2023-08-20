--[[ Bound to m_hud ]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local health = {}
health.__index = health

function health.init(self)
    local new = {}
    local frame = self.healthfr
    new.healthfr = frame
    return setmetatable(new, health)
end

function health:update()
    
    local frame = self.healthfr
    local healthBarFrame = frame.HealthBarFrame
	local bar = healthBarFrame.Bar
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local currentShield = player:GetAttribute("shield")
	if currentShield == nil or not currentShield then currentShield = 0 end
	
	health = math.floor(hum.Health + currentShield)
	frame.HealthLabel.Text = tostring(health) .. " HP"
	
	bar.HealthGrad.Enabled = true
	bar.LowHealthGrad.Enabled = false
	bar.ShieldGrad.Enabled = false
	
	if currentShield and currentShield > 0 then
		bar.HealthGrad.Enabled = false
		bar.LowHealthGrad.Enabled = false
		bar.ShieldGrad.Enabled = true
	else
		if health <= 25 then
			bar.HealthGrad.Enabled = false
			bar.LowHealthGrad.Enabled = true
			bar.ShieldGrad.Enabled = false
		end
	end
	
	-- health 150 to account for the possible 50 shield
	-- cap gui's max health at 150 so bar doesnt get too big
	if health > 100 then health = 100 end
	bar.Size = UDim2.new(health/100, 0, 1, 0)
    bar.Position = UDim2.new(1 - (health/100), 0, 0, 0)
end

--


return health
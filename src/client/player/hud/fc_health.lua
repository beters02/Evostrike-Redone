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
    new.healthvar = {
        defSize = frame.HeartIcon.Size,
        defPos = frame.HeartIcon.Position,
        lowAnimThread = nil,
        lowAnimPlaying = false,
    }

    local _uipos = UDim2.new(new.healthvar.defSize.X.Scale - (.2 - new.healthvar.defSize.X.Scale), 0, new.healthvar.defPos.Y.Scale - (1.1 - new.healthvar.defSize.Y.Scale), 0)
    local ui = {ti = TweenInfo.new(.3), goal = {Size = UDim2.new(.2, 0, 1.1, 0), Position = _uipos}}
    local di = {ti = TweenInfo.new(0.4), goal = {Size = new.healthvar.defSize, Position = new.healthvar.defPos}}

    new.healthvar.tweens = {
        up = TweenService:Create(frame.HeartIcon, ui.ti, ui.goal),
        down = TweenService:Create(frame.HeartIcon, di.ti, di.goal)
    }

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
		frame.HeartIcon.Visible = false
		frame.ShieldIcon.Visible = true
	else
		
		frame.HeartIcon.Visible = true
		frame.ShieldIcon.Visible = false
		
		if health <= 25 then
            
			if not self.healthvar.lowAnimPlaying then
				self:lowHealthAnimation(true)
			end
            
			bar.HealthGrad.Enabled = false
			bar.LowHealthGrad.Enabled = true
			bar.ShieldGrad.Enabled = false
		else

			if self.healthvar.lowAnimPlaying then
                self:lowHealthAnimation(false)
            end
		end
	end
	
	-- health 150 to account for the possible 50 shield
	-- cap gui's max health at 150 so bar doesnt get too big
	if health > 150 then health = 150 end
	bar.Size = UDim2.new(health/150, 0, 1, 0)
	
	frame.PlayerNameLabel.Text = tostring(player.Name)
end

--

function health:lowHealthAnimation(play: boolean)
    if play then
        self.healthvar.lowAnimPlaying = true
        self.healthvar.lowAnimThread = task.spawn(function()
            while true do
                self.healthvar.tweens.up:Play()
                self.healthvar.tweens.up.Completed:Wait()
                self.healthvar.tweens.down:Play()
                self.healthvar.tweens.down.Completed:Wait()
            end
        end)
    elseif not play then
        self.healthvar.lowAnimPlaying = false
        coroutine.yield(self.healthvar.lowAnimThread)
    end
end

return health
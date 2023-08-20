local LocalizationService = game:GetService("LocalizationService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

local options = {}
options.__index = options

function options:Open()
	self:Connect()
	self.Location.Visible = true
end

function options:Close()
	self:Disconnect()
	self.Location.Visible = false
end

--

function options:init(main)
    self = setmetatable(self, options)
	local clientPlayerDataModule = require(Framework.shm_clientPlayerData.Location)

	-- wait for data module to init
	if not clientPlayerDataModule.stored then
		repeat task.wait() until clientPlayerDataModule.stored
	end

	self.connections = {}
	self.player = main.player
	self.playerdata = clientPlayerDataModule
	self.crosshairModule = self:_getPlayerCrosshairModule()
	self.crosshairFrame = self.Location.General.Crosshair

	self:_updateCrosshairFrame()
    return self
end

--

function options:Connect()
	self:_connectCrosshairFrame()
end

function options:Disconnect()
	for i, v in pairs(self.connections) do
		v:Disconnect()
	end
	self.connections = {}
end

--

function options:_connectCrosshairFrame()
	for i, tab in pairs({Crosshair = self.crosshairFrame:GetChildren()}) do 
		for _, frame in pairs(tab) do
			if not frame:IsA("Frame") then continue end

			local textBox = frame:FindFirstChildWhichIsA("TextBox")
			if textBox then
				table.insert(self.connections, textBox.FocusLost:Connect(function(enterPressed)
					self:_typingFocusFinished(enterPressed, textBox, frame)
				end))
				continue
			end

			local textButton = frame:FindFirstChildWhichIsA("TextButton")
			if textButton then
				table.insert(self.connections, textButton.MouseButton1Click:Connect(function()
					--optionsBooleanInteract(textButton, i)
				end))
			end
		end
	end
end

--

function options:_typingFocusFinished(enterPressed, button, frame, isButton)
	local parentSettingDataPrefix = frame:FindFirstAncestorWhichIsA("Frame"):GetAttribute("DataPrefix")
	local dataKey = string.lower(string.sub(frame.Name, 3))
	local currValue = self.playerdata.get(parentSettingDataPrefix, dataKey)

	if enterPressed then
		local newValue = tonumber(button.Text)
		if not newValue then
			button.Text = tostring(currValue)
			return
		end

		--main.page.options.profile[parentSettingDataPrefix][dataKey] = newValue
		self.playerdata.set(parentSettingDataPrefix, dataKey, newValue)

		if parentSettingDataPrefix == "crosshair" then
			self:_updateCrosshairFrame()
			self.crosshairModule:updateCrosshair(dataKey, newValue)
		end
	else
		button.Text = tostring(currValue)
	end
end

function options:_updateCrosshairFrame()
	for _, frame in pairs(self.crosshairFrame:GetChildren()) do
		if not frame:IsA("Frame") then continue end
		local dataKey = string.lower(string.sub(frame.Name, 3))
		frame:WaitForChild("button").Text = tostring(self.playerdata.get("crosshair", dataKey))
	end
end

function options:_getPlayerCrosshairModule()
	local module = require(self.player.Character:WaitForChild("crosshair"):WaitForChild("m_crosshair"))
	if not module._isInit then repeat task.wait() until module._isInit end
	return module
end

return options
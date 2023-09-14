local general = {}

function general:_baseConnectFrame(frameTable)
	for i, tab in pairs(frameTable) do
		for _, frame in pairs(tab) do
			if not frame:IsA("Frame") then continue end
			local textBox = frame:FindFirstChildWhichIsA("TextBox")
			if textBox then
				table.insert(self.pageconnections, textBox.FocusLost:Connect(function(enterPressed)
					self:_typingFocusFinished(enterPressed, textBox, frame)
				end))
				continue
			end

			local textButton = frame:FindFirstChildWhichIsA("TextButton")
			if textButton then
				table.insert(self.pageconnections, textButton.MouseButton1Click:Connect(function()
					--generalBooleanInteract(textButton, i)
				end))
			end
		end
	end
end

function general:_connectCrosshairFrame()
	self:_baseConnectFrame({Crosshair = self.crosshairFrame:GetChildren()})
end

function general:_connectViewmodelFrame()
	self:_baseConnectFrame({Viewmodel = self.viewmodelFrame:GetChildren()})
end

--

function general:_typingFocusFinished(enterPressed, button, frame, isButton)
	local parentSettingDataPrefix = frame:FindFirstAncestorWhichIsA("Frame"):GetAttribute("DataPrefix")
	local dataKey = frame:GetAttribute("DataName") or string.lower(string.sub(frame.Name, 3))
	local currValue = self.playerdata:Get("options." .. parentSettingDataPrefix ..  "." .. dataKey)

	if enterPressed then
		local newValue = tonumber(button.Text)
		if not newValue then
			button.Text = tostring(currValue)
			return
		end

		--main.page.options.profile[parentSettingDataPrefix][dataKey] = newValue
		local new, wasChanged, notChangedError = self.playerdata:Set("options." .. parentSettingDataPrefix ..  "." .. dataKey, newValue)
		if not wasChanged then
			
		end

		if parentSettingDataPrefix == "crosshair" then
			self:_updateCrosshairFrame()
			self.crosshairModule:updateCrosshair(dataKey, newValue)
		elseif parentSettingDataPrefix == "camera" then
			-- fire viewmodel script event
			self:_updateViewmodelFrame()
		end

	else
		button.Text = tostring(currValue)
	end
end

function general:_updateCrosshairFrame()
	for _, frame in pairs(self.crosshairFrame:GetChildren()) do
		if not frame:IsA("Frame") then continue end
		local dataKey = string.lower(string.sub(frame.Name, 3))
		frame:WaitForChild("button").Text = tostring(self.playerdata:Get("options.crosshair." .. dataKey))
	end
end

function general:_updateViewmodelFrame()
	for _, frame in pairs(self.viewmodelFrame:GetChildren()) do
		if not frame:IsA("Frame") then continue end
		local dataKey = frame:GetAttribute("DataName")
		frame:WaitForChild("button").Text = tostring(self.playerdata:Get("options.camera." .. dataKey))
	end
end

function general:_getPlayerCrosshairModule()
	if not self.player.Character then
		self.player.CharacterAdded:Once(function()
			local module = require(self.player.Character:WaitForChild("CrosshairScript"):WaitForChild("m_crosshair"))
			if not module._isInit then repeat task.wait() until module._isInit end
			self.crosshairModule = module
		end)
		return false
	end
	local module = require(self.player.Character:WaitForChild("CrosshairScript"):WaitForChild("m_crosshair"))
	if not module._isInit then repeat task.wait() until module._isInit end
	return module
end

return general
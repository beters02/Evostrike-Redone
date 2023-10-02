local module = {
	stateName = "UI",
	var = {
		openUIs = {}
	}
}

-- A ui can be any UI element that has the Enabled or Visible property.
function module:addOpenUI(uiName, ui, mouseIconEnabled)
	
	if not uiName then warn("Must specifiy UI name.") return false end

	-- we dont want to add the same UI twice here
	if self.var.openUIs[uiName] then
		warn("C_UI Cannot open the same UI twice. " .. tostring(uiName))
		return false
	end

	-- set as new table so changed event fires
	local new = self.var.openUIs
	new[uiName] = {UI = ui, MouseIconEnabled = mouseIconEnabled or false}
	return self:set(self.player, "openUIs", new)
end

-- Remove an open UI from the state data
function module:removeOpenUI(uiName)
	-- set as new table so changed event fires
	local new = self.var.openUIs
	new[uiName] = nil
	return self:set(self.player, "openUIs", new)
end

function module:hasOpenUI()
	local count = 0
	for _, v in pairs(self:get(self.players, "openUIs")) do
		if v then return true end
	end
	return false
end

-- check if mouse icon should be enabled depending on currently open uis
function module:shouldMouseBeEnabled() -- to be deprecated name is bad
	for i, v in pairs(self.var.openUIs) do
		if v.MouseIconEnabled then return true end
	end
	return false
end
module.shouldMouseIconBeEnabled = module.shouldMouseBeEnabled

return module
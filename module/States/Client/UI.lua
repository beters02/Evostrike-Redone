local UI = {
    properties = {
        id = "UI",
        replicated = false,
        clientReadOnly = false,
        owner = "Client"
    },
    defaultVar = { openUIs = {} }
}

-- A ui can be any UI element that has the Enabled or Visible property.
function UI:addOpenUI(uiName, ui, mouseIconEnabled)
	if not uiName then warn("Must specifiy UI name.") return false end

	-- we dont want to add the same UI twice here
	if self._variables.openUIs[uiName] then
		warn("C_UI Cannot open the same UI twice. " .. tostring(uiName))
		return false
	end

	-- set as new table so changed event fires
	local new = self._variables.openUIs
	new[uiName] = {UI = ui, MouseIconEnabled = mouseIconEnabled or false}
	return self:set("openUIs", new)
end

-- Remove an open UI from the state data
function UI:removeOpenUI(uiName)
	-- set as new table so changed event fires
	local new = self._variables.openUIs
	new[uiName] = nil
	return self:set("openUIs", new)
end

function UI:clearOpenUIs()
	self:set("openUIs", {})
end

function UI:hasOpenUI()
	for _, v in pairs(self:get("openUIs")) do
		if v then return true end
	end
	return false
end

function UI:getOpenUI(uiName)
	return self._variables.openUIs[uiName]
end

-- check if mouse icon should be enabled depending on currently open uis
function UI:shouldMouseBeEnabled() -- to be deprecated name is bad
	for _, v in pairs(self._variables.openUIs) do
		if v.MouseIconEnabled then return true end
	end
	return false
end
UI.shouldMouseIconBeEnabled = UI.shouldMouseBeEnabled

return UI
local LocalizationService = game:GetService("LocalizationService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

local options = {}

function options:init(main)
    self = setmetatable(self, options)
	local clientPlayerDataModule = require(Framework.shm_clientPlayerData.Location)

	-- wait for data module to init
	if not clientPlayerDataModule.stored then
		repeat task.wait() until clientPlayerDataModule.stored
	end

	-- compile options page module functions
	_compile(self)

	self.connections = {}
	self.pageconnections = {}
	self.player = main.player
	self.playerdata = clientPlayerDataModule
	self.crosshairModule = self:_getPlayerCrosshairModule()
	self.crosshairFrame = self.Location.General.Crosshair
	self.viewmodelFrame = self.Location.General.Viewmodel
	self.keybindsFrame = self.Location.Keybinds
	
	self:_updateCrosshairFrame()
	self:_updateViewmodelFrame()
	self:_updateKeybindsFrame()
    return self
end

function _compile(self)
	for _, child in pairs(self._mainPageModule._loc.Options:GetChildren()) do
		if not child:IsA("ModuleScript") then continue end
		for index, moduleElement in pairs(require(child)) do
			self[index] = moduleElement
		end
	end
end

--

function options:Open()
	self:ConnectMain()
	self:SetCurrentOptionsPageOpen("general") -- open with general page
	self.Location.Visible = true
end

function options:Close()
	self.Location.Visible = false
	self:DisconnectMain()
	self:DisconnectPageConnections()
end

function options:SetCurrentOptionsPageOpen(page: string)
	if page == "general" then
		self._currentOptionsPage = "general"
		self:DisconnectPageConnections()
		self.Location.Keybinds.Visible = false
		self.Location.General.Visible = true
		self:_connectCrosshairFrame()
		self:_connectViewmodelFrame()
	elseif page == "keybinds" then
		self._currentOptionsPage = "keybinds"
		self:DisconnectPageConnections()
		self.Location.General.Visible = false
		self.Location.Keybinds.Visible = true
		self:_connectKeybindsFrame()
	end
end

--

function options:ConnectMain()
	self.connections = {

		self.Location.GeneralButton.MouseButton1Click:Connect(function()
			if self._currentOptionsPage == "general" then return end
			options:SetCurrentOptionsPageOpen("general")
		end),

		self.Location.KeybindsButton.MouseButton1Click:Connect(function()
			if self._currentOptionsPage == "keybinds" then return end
			options:SetCurrentOptionsPageOpen("keybinds")
		end),

	}
end

function options:DisconnectMain()
	for i, v in pairs(self.connections) do
		v:Disconnect()
	end
	self.connections = {}
end

function options:DisconnectPageConnections()
	for i, v in pairs(self.pageconnections) do
		v:Disconnect()
	end
	self.pageconnections = {}
end

return options
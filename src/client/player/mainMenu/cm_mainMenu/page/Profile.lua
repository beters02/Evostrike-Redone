local LocalizationService = game:GetService("LocalizationService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

local profile = {}

function profile:Open()
	self:Connect()
	self.Location.Visible = true
end

function profile:Close()
	self:Disconnect()
	self.Location.Visible = false
end

--

function profile:init(main)
    self = setmetatable(self, profile)
	local clientPlayerDataModule = require(Framework.shm_clientPlayerData.Location)

	-- wait for data module to init
	if not clientPlayerDataModule.stored then
		repeat task.wait() until clientPlayerDataModule.stored
	end

	self.connections = {}
	self.player = main.player
	self.playerdata = clientPlayerDataModule
    self.Location.PlayerName.Text = self.player.Name
	
    return self
end

--

function profile:Connect()

end

function profile:Disconnect()
	for i, v in pairs(self.connections) do
		v:Disconnect()
	end
	self.connections = {}
end

return profile
local LocalizationService = game:GetService("LocalizationService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

local options = {}

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

    print(self)

	self.connections = {}
	self.player = main.player
	self.playerdata = clientPlayerDataModule
    self.Location.PlayerName.Text = self.player.Name
	
    return self
end

--

function options:Connect()

end

function options:Disconnect()
	for i, v in pairs(self.connections) do
		v:Disconnect()
	end
	self.connections = {}
end

return options
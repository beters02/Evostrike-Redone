local LocalizationService = game:GetService("LocalizationService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData.Client)
local Strings = require(Framework.Module.lib.fc_strings)

local Stats = {}

function Stats:Open()
	self:Connect()
	self:OpenAnimations()
end

function Stats:Close()
	self:Disconnect()
	self.Location.Visible = false
end

--

function Stats:init(main)
    self = setmetatable(self, Stats)

	self.connections = {}
	self.player = main.player
    self.Location.PlayerName.Text = self.player.Name

	self.statsObjs = {}
	--[[_statObjs._pc = {path = "economy.premiumCredits", label = self.Location.PCAmountLabel}
	_statObjs._sc = {path = "economy.strafeCoins", label = self.Location.SCAmountLabel}
	_statObjs._xp = {path = "economy.xp", label = self.Location:WaitForChild("AccountLevelFrame"):WaitForChild("PlayerXP"), suffix = " XP"}
	_statObjs._wins = {path = "pstats.wins", label = self.Location.StatsFrame.Wins.Amount}
	_statObjs._losses = {path = "pstats.losses", label = self.Location.StatsFrame.Losses.Amount}
	_statObjs._kills = {path = "pstats.kills", label = self.Location.StatsFrame.Kills.Amount}
	_statObjs._deaths = {path = "pstats.deaths", label = self.Location.StatsFrame.Deaths.Amount}
	self.statObjs = _statObjs]]

	--_updateAll(self)
    return self
end

--

function Stats:Connect()
	for i, obj in pairs(self.statObjs) do
		self.connections[i.."Changed"] = PlayerData:PathValueChanged(obj.path, function(new)
			obj.label.Text = tostring(new)
			if obj.suffix then
				obj.label.Text = obj.label.Text .. obj.suffix
			end
		end)
	end
end

function Stats:Disconnect()
	for i, v in pairs(self.connections) do
		v:Disconnect()
	end
	self.connections = {}
end

--

function _updateAll(self)
	local playerdata = PlayerData:Get()
	for _, obj in pairs(self.statObjs) do
		local newStr = tostring(Strings.convertPathToInstance(obj.path, playerdata))
		if obj.suffix then
			newStr = newStr .. obj.suffix
		end
		obj.label.Text = newStr
	end
end

return Stats
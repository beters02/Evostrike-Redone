local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local PlayerData = require(Framework.Module.PlayerData.Client)
local Strings = require(Framework.Module.lib.fc_strings)

local Page = require(script.Parent)
local Stats = setmetatable({}, Page)
Stats.__index = Stats

function Stats:Open()
    self._Open()
	self:Connect()
end

function Stats:Close()
    self._Close()
	self:Disconnect()
end

--

function Stats.new(mainMenu, frame)
    local self = setmetatable(Page.new(mainMenu, frame), Stats)
    self.connections = {}
	self.player = game.Players.LocalPlayer
    self.Frame.PlayerName.Text = self.player.Name

	self.statObjs = {
        pc = {path = "economy.premiumCredits", label = self.Frame.PCAmountLabel},
        sc = {path = "economy.strafeCoins", label = self.Frame.SCAmountLabel},
        xp = {path = "economy.xp", label = self.Frame.AccountLevelFrame:WaitForChild("PlayerXP"), suffix = " XP"},
        wins = {path = "pstats.wins", label = self.Frame.StatsFrame.Wins.Amount},
        losses = {path = "pstats.losses", label = self.Frame.StatsFrame.Losses.Amount},
        kills = {path = "pstats.kills", label = self.Frame.StatsFrame.Kills.Amount},
        deaths = {path = "pstats.deaths", label = self.Frame.StatsFrame.Deaths.Amount}
    }
	
	updateAll(self)
    return self
end

--

function Stats:Connect()
	for i, obj in pairs(self.statObjs) do
		self.connections[i.."Changed"] = statObjectChanged(obj)
	end
end

function Stats:Disconnect()
	for _, v in pairs(self.connections) do
		v:Disconnect()
	end
	self.connections = {}
end

function Stats:Update()
    updateAll(self)
end

--

function updateAll(self)
	local playerdata = PlayerData:Get()
	for _, obj in pairs(self.statObjs) do
		local newStr = tostring(Strings.convertPathToInstance(obj.path, playerdata))
		if obj.suffix then
			newStr = newStr .. obj.suffix
		end
		obj.label.Text = newStr
	end
end

function statObjectChanged(obj)
    return PlayerData:PathValueChanged(obj.path, function(new)
        obj.label.Text = tostring(new)
        if obj.suffix then
            obj.label.Text = obj.label.Text .. obj.suffix
        end
    end)
end

return Stats
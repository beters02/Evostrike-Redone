local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

function getPlayerAvatar(player: Player)
    return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end

function convertSecToMin(sec: number)
    local _sec = sec % 60
    if _sec < 10 then
        _sec = "0"..tostring(_sec)
    end
	return tostring(math.floor(sec/60)) .. ": " .. tostring(_sec)
end

local TopBar = {}
TopBar.__index = TopBar
local Gui = script:WaitForChild("Gui")

function TopBar.init(player, enemy)
    local self = setmetatable({}, TopBar)
    self.Player = player
    self.Connections = {}

    local gui = Gui:Clone()
    local mainFr = gui:WaitForChild("MainFrame")
    local playerInfoFr, enemyInfoFr = mainFr:WaitForChild("PlayerInfoFrame"), mainFr:WaitForChild("EnemyInfoFrame")
    local scoreFr, timerFr, roundFr = mainFr:WaitForChild("ScoreFrame"), mainFr:WaitForChild("TimerFrame"), mainFr:WaitForChild("RoundFrame")

    playerInfoFr:WaitForChild("TextLabel").Text = player.Name
    playerInfoFr:WaitForChild("ImageLabel").Image = getPlayerAvatar(player)
    enemyInfoFr:WaitForChild("TextLabel").Text = enemy.Name
    enemyInfoFr:WaitForChild("ImageLabel").Image = getPlayerAvatar(enemy)

    gui.Parent = player.PlayerGui
    self.Gui = gui
    self.PlayerInfoFrame, self.EnemyInfoFrame = playerInfoFr, enemyInfoFr
    self.ScoreFrame, self.TimerFrame, self.RoundFrame = scoreFr, timerFr, roundFr
    return self
end

function TopBar:ChangeScore(data)
    for plrName, newScore in pairs(data) do
        local label = plrName == self.Player.Name and self.ScoreFrame.PlayerKills or self.ScoreFrame.EnemyKills
        label.Text = tostring(newScore)
    end
end

function TopBar:ChangeRound(round)
    self.RoundFrame.TextLabel.Text = "Round " .. tostring(round)
end

function TopBar:StartTimer(length)
    if self.Connections.Timer then
        self.Connections.Timer:Disconnect()
        self.Connections.Timer = nil
        task.wait()
    end
    if not length then
        return
    end
    local endTick = tick() + length
    self.Connections.Timer = RunService.RenderStepped:Connect(function()
        if tick() >= endTick then
            self.Connections.Timer:Disconnect()
            return
        end
        self.TimerFrame.TextLabel.Text = convertSecToMin(math.floor(endTick - tick()))
    end)
end

function TopBar:Destroy()
    for _, v in pairs(self.Connections) do
        v:Disconnect()
    end
    self.Gui:Destroy()
end

return TopBar
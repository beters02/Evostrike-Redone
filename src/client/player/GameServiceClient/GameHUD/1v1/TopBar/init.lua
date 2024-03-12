--[[ NEW, SAFER WAY TO DISTRIBUTE GUIS FROM THE SERVER

Copy this script and put it on the Character, Backpack or PlayerGui
Listen for remotes or whatever, call a Cleanup remote if necessary, destroy the script when ready
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local gui = script:WaitForChild("Gui")
local mainFrame = gui:WaitForChild("MainFrame")

local _lpfr = mainFrame:WaitForChild("LeaderboardPlaceFrame")
local leaderboardPlaceUI = {frame = _lpfr, textLabel = _lpfr:WaitForChild("TextLabel")}

local _sfr = mainFrame:WaitForChild("ScoreFrame")
local scoreUI = {frame = _sfr, killsLabel = _sfr:WaitForChild("Kills"), deathsLabel = _sfr:WaitForChild("Deaths")}

local _tfr = mainFrame:WaitForChild("TimerFrame")
local timerUI = {frame = _tfr, textLabel = _tfr:WaitForChild("TextLabel")}

local _pifr = mainFrame:WaitForChild("PlayerInfoFrame")
local playerInfoUI = {frame = _pifr, imageLabel = _pifr:WaitForChild("ImageLabel"), textLabel = _pifr:WaitForChild("TextLabel")}

local timer = false
local timerLength = script:GetAttribute("TimerLength") or 3
local remoteConn = false

--[[ Utility ]]
local function convertSecToMin(sec: number)
    local _sec = sec % 60
    if _sec < 10 then
        _sec = "0"..tostring(_sec)
    end
	return tostring(math.floor(sec/60)) .. ": " .. tostring(_sec)
end

local function getPlayerAvatar(player: Player)
    return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end

-- [[ Main ]]

local TopBar = {}

function TopBar:Enable(uiContainer, timeLength)
    playerInfoUI.imageLabel.Image = getPlayerAvatar(localPlayer)
    playerInfoUI.textLabel.Text = localPlayer.Name
    --gui.Parent = uiContainer
    gui.Enabled = true
    self:StartTimer(uiContainer, timeLength)
end

function TopBar:UpdateScoreFrame(uiContainer, kills, deaths)
    if kills then
        scoreUI.killsLabel.Text = tostring(kills)
    end
    if deaths then
        scoreUI.deathsLabel.Text = tostring(deaths)
    end
end

function TopBar:StartTimer(uiContainer, length)
    if timer then
        timer:Disconnect()
    end
    local endt = tick() + length
    timer = RunService.RenderStepped:Connect(function()
        if tick() >= endt then self:StopTimer() return end
        timerUI.textLabel.Text = convertSecToMin(math.floor(endt - tick()))
    end)
end

function TopBar:StopTimer()
    if timer then
        timer:Disconnect()
        timer = nil
    end
end

function TopBar:Destroy()
    self:StopTimer()
    gui:Destroy()
    remoteConn:Disconnect()
end

return TopBar

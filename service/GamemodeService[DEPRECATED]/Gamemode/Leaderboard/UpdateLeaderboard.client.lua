local Players = game:GetService("Players")
local GamemodeService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services").GamemodeService)
local UpdateLeaderboard: RemoteEvent = script.Parent:WaitForChild("UpdateLeaderboardEvent")

local itemframe = script.Parent:WaitForChild("MainFrame"):WaitForChild("Content"):WaitForChild("ItemFrame")
local _plrs = {}

export type lplr = {
	player: Player,
	frame: Frame,
	kills: number,
	deaths: number
}

local function init()
	local plrdata = GamemodeService:GetPlayerData()
	for _, v in pairs(plrdata) do
		addPlayer(v.Player, v.Kills, v.Deaths)
	end

    Players.PlayerAdded:Connect(function(player)
        addPlayer(player)
        print("+" .. player.Name)
    end)

    Players.PlayerRemoving:Connect(function(player)
        removePlayer(player)
        print("-" .. player.Name)
    end)

    UpdateLeaderboard.OnClientEvent:Connect(function(_plrdata)
        for _, v in pairs(_plrdata) do
            if not _plrs[v.Player.Name] then addPlayer(v.Player) end
            _plrs[v.Player.Name].kills = v.Kills
            _plrs[v.Player.Name].deaths = v.Deaths
        end
        updateLeaderboardTexts()
    end)
end

function createItemFrame(player)
	local frame = itemframe:Clone()
	frame.Name = player.Name .. "_Frame"

    -- position yourself on the top of leaderboard
    if player == Players.LocalPlayer then
        frame.Name = "1_" .. frame.Name
    else
        frame.Name = "2_" .. frame.Name
        -- destroy "kills, deaths, kdr" labels for all other frames
        for _, v in pairs(frame:GetChildren()) do
            if v.Name == "killsLabel" then
                v:Destroy()
            end
        end
    end

    frame.playerName.Text = tostring(player.Name)
    frame.Visible = true
    frame.Parent = script.Parent.MainFrame.Content
    return frame
end

function addPlayer(player, kills, deaths)
	if not _plrs[player.Name] then
		_plrs[player.Name] = {
			player = player,
			frame = createItemFrame(player),
            kills = kills or 0,
            deaths = deaths or 0
		} :: lplr
        updatePlayerLeaderboardText(player)
	end
end

function removePlayer(player)
	if _plrs[player.Name] then
        _plrs[player.Name].frame:Destroy()
        _plrs[player.Name] = nil
    end
end

function updatePlayerLeaderboardText(player)
    local _lplr = _plrs[player.Name]
    _lplr.frame:WaitForChild("kills").Text = tostring(_lplr.kills)
    _lplr.frame:WaitForChild("deaths").Text = tostring(_lplr.deaths)

    local kdr

    if (_lplr.kills == 0 and _lplr.deaths == 0) or (_lplr.kills == 0 and _lplr.deaths > 0) then
        kdr = 0
    elseif _lplr.deaths == 0 and _lplr.kills > 0 then
        kdr = 1
    else
        kdr = math.round(_lplr.kills/_lplr.deaths)
    end

    _lplr.frame:WaitForChild("kdr").Text = tostring(kdr)
end

function updateLeaderboardTexts()
    for _, v in pairs(_plrs) do
        updatePlayerLeaderboardText(v.player)
    end
end

init()
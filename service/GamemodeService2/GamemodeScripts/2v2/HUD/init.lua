-- HUD Module given to players

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GamemodeEvents = ReplicatedStorage:WaitForChild("GamemodeEvents")

local guis = script:WaitForChild("Guis")
local module = script

local HUD = {
    _connections = {},

    player = false,
    yourTeam = {},
    enemyTeam = {},

    started = false,

    guis = {
        topBar = false,
        tbarTimerFrame = false,
        tbarYourScoreLabel = false,
        tbarEnemyScoreLabel = false,
        buyMenu = false,
        overlay = false
    },

    events = {
        START = true
    }
}

--@summary Called while Game is initialized, (before teams are assigned)
function HUD:init()

    GamemodeEvents.HUD.EnableBind:Fire(false)

    local _eventsFold = Instance.new("Folder", module)
    _eventsFold.Name = "Events"

    -- temporary bind events
    for i, _ in pairs(HUD.events) do
        HUD.events[i] = Instance.new("BindableEvent", _eventsFold)
        HUD.events[i].Name = i
    end

    HUD.player = game.Players.LocalPlayer

    -- add top bar
    HUD.guis.topBar = guis.TopBar
    HUD.guis.tbarTimerFrame = guis.TopBar:WaitForChild("Gui"):WaitForChild("MainFrame"):WaitForChild("TimerFrame")
    HUD.guis.tbarYourScoreLabel = guis.TopBar.Gui.MainFrame:WaitForChild("ScoreFrame"):WaitForChild("PlayerScore")
    HUD.guis.tbarEnemyScoreLabel = guis.TopBar.Gui.MainFrame.ScoreFrame:WaitForChild("EnemyScore")

    -- add hud overlay
    HUD.guis.overlay = guis.Overlay
    HUD.guis.overlay.Parent = HUD.player.PlayerGui

    -- TODO: init waiting for players camera
    HUD._connections.hudStart = GamemodeEvents.HUD.START.OnClientEvent:Connect(function(...)
        HUD:StartGame(...)
        HUD.events.START:Fire(...)
    end)
    HUD._connections.hudEnd = GamemodeEvents.HUD.END.OnClientEvent:Connect(function(...)
        print('Penis!')
        HUD:EndGame(...)
    end)
    HUD._connections.startTimer = GamemodeEvents.HUD.StartTimer.OnClientEvent:Connect(function(length)
        self:StartTimer(length)
    end)
    HUD._connections.changeRound = GamemodeEvents.HUD.ChangeRound.OnClientEvent:Connect(function(you, enemy)
        self:ChangeRound(you, enemy)
    end)
end

function HUD:StartGame(teamName: string, yourTeamNames, enemyTeamNames)
    if HUD.started then return end
    HUD.started = true

    -- init teams (if can't find player, player = "Bot")
    HUD.yourTeam.You = HUD.player
    HUD.yourTeam.Teammate = get_player(yourTeamNames[1]) or "Bot"
    HUD.enemyTeam.Enemy1 = get_player(enemyTeamNames[1]) or "Bot"
    HUD.enemyTeam.Enemy2 = get_player(enemyTeamNames[2]) or "Bot"

    -- add buy menu
    HUD.guis.buyMenu = guis.BuyMenu
end

function HUD:EndGame()
    GamemodeEvents.HUD.EnableBind:Fire(true)
end

function HUD:StartRound()
    
end

function HUD:EndRound()
    
end

function HUD:StartTimer(length)
    if HUD._connections.timer then
        HUD._connections.timer:Disconnect()
    end
    HUD._connections.timer = RunService.RenderStepped:Connect(function(dt)
        length -= dt
        if length <= 0 then
            HUD._connections.timer:Disconnect()
            return
        end
        self.guis.tbarTimerFrame.TextLabel.Text = sec_to_min(length)
    end)
end

function HUD:ChangeRound(you: number?, enemy: number?)
    if you then
        self.guis.tbarYourScoreLabel.Text = tostring(you)
    end
    if enemy then
        self.guis.tbarEnemyScoreLabel.Text = tostring(enemy)
    end
end

--

function get_player(plrName)
    local success, result = pcall(function()
        return Players[plrName]
    end)
    if success then
        return result
    end
    return false
end

function sec_to_min(sec: number)
    sec = math.floor(sec)
    local _sec = sec % 60
    if _sec < 10 then
        _sec = "0"..tostring(_sec)
    end
    return tostring(math.floor(sec/60)) .. ": " .. tostring(_sec)
end

return HUD
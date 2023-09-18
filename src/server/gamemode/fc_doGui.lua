                        -- [[ Module for organizing the usage of gamemode GUIs ]]
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local TweenService = game:GetService("TweenService")
local FadeScreenOut = require(Framework.Module.lib.m_fadescreenout)

local gui = {}

-- 1v1 SPECIFIC FUNCTIONS
local _1v1 = {}

function _1v1:InitPlayerGuiAll()
    for i, v in pairs(self.players) do
        if typeof(v) == "table" then continue end

        local _bar = self.Location.GamemodeBar:Clone()
        self.Location.gamemodeGuiMain:Clone().Parent = _bar

        local enemyobj = Instance.new("ObjectValue")
        enemyobj.Name = "EnemyObject"

        local otherPlayer = self:GetOtherPlayer(v)
        if type(otherPlayer) == "table" then -- this is a bot
            enemyobj.Value = otherPlayer.Character
        else
            enemyobj.Value = otherPlayer
        end

        enemyobj.Parent = _bar

        _bar.Parent = v.PlayerGui
    end
end

function _1v1:UpdateGuiScoreAll()
    for i, v in pairs(self.players) do
        if not Players:GetPlayers(v.Name) then continue end
        v.PlayerGui.GamemodeBar.RemoteEvent:FireClient(v, "UpdateScore", self.playerdata[v.Name].wins, self.playerdata[self:GetOtherPlayer(v).Name].wins)
    end
end

function _1v1:StartGuiTimerAll(length)
    for i, v in pairs(self.players) do
        if not Players:GetPlayers(v.Name) then continue end
        v.PlayerGui.GamemodeBar.RemoteEvent:FireClient(v, "StartTimer", length)
    end
end

function _1v1:StopGuiTimerAll()
    for i, v in pairs(self.players) do
        if not Players:GetPlayers(v.Name) then continue end
        v.PlayerGui.GamemodeBar.RemoteEvent:FireClient(v, "StopTimer")
    end
end

-- Make screen black

function _1v1:FadeScreenIn(v: Player, callback) -- optional callback on finish
    if not self.var.fades then self.var.fades = {} end -- save so we can fade in during spawn
    self.var.fades[v.Name] = FadeScreenOut(v)
    self.var.fades[v.Name].In:Play()
    if callback then
        task.delay(self.var.fades[v.Name].InLength, callback)
    end
end

function _1v1:FadeScreenInAll(callback)
    for i, v in pairs(self.players) do
        self:FadeScreenIn(v, callback)
    end
end

-- Remove black screen

function _1v1:FadeScreenOut(v: Player, callback) 
    if self.var.fades[v.Name] then
        self.var.fades[v.Name].OutWrap()
        task.delay(self.var.fades[v.Name].OutLength, function()
            self.var.fades = {}
            if callback then callback() end
        end)
    end
end

function _1v1:FadeScreenOutAll()
    if self.var.fades then
        for i, v in pairs(self.var.fades) do
            v.OutWrap()
            if i == #self.var.fades then
                task.delay(v.OutLength, function()
                    self.var.fades = {}
                end)
            end
        end
    end
end

function _1v1:WaitingScreen(player)
    self:FadeScreenIn(player, function()
        self.Location.WaitingForPlayers:Clone().Parent = player.PlayerGui
        self:FadeScreenOut(player)
    end)
end

function _1v1:WaitingScreenAll()
    for i, v in pairs(self.players) do
        self:WaitingScreen(v)
    end
end

function _1v1:RemoveWaitingScreenAll(fadeBackOut: boolean)
    for i, v in pairs(self.players) do
        if not v.PlayerGui.FindFirstChild then continue end
        if v.PlayerGui:FindFirstChild("WaitingForPlayers") then
            self:FadeScreenIn(v, function()
                v.PlayerGui.WaitingForPlayers:Destroy()
                if fadeBackOut then self:FadeScreenOut() end
            end)
        end
    end
end

-- Sent to all players when a round is won
function _1v1:RoundWonScreen(winner, loser)

    -- this is so fucking stupid and took me actually 8 years longer than it had to of.
    -- just use an animate script on the gui for fucks sake
    
    -- set up gui variables
    local winmsg = self:GetRandomWinMessage()

    -- create gui clones
    local guis = {}
    for i, plr in pairs(self.players) do
        guis[i] = {self.Location.RoundWonGui:Clone()}
        guis[i][1].Frame.MessageLabel = tostring(winmsg)
        guis[i][1].Frame.WinnerLabel = tostring(winner.Name)
        guis[i][1].Frame.LoserLabel = tostring(loser.Name)

        -- init tweens
        guis[i][2] = {} -- in
        guis[i][3] = {} -- out
        for _, textLabel in pairs(guis[i][1]:GetChildren()) do
            table.insert(
                guis[i][2],
                TweenService:Create(textLabel, TweenInfo.new(1), {TextTransparency = 0})
            )
            table.insert(
                guis[i][3],
                TweenService:Create(textLabel, TweenInfo.new(1), {TextTransparency = 1})
            )
            textLabel.TextTransparency = 1
        end
        guis[i][1].Parent = plr.PlayerGui
    end

    -- play in tweens
    for _, _gui in pairs(guis) do
        for _, tween in pairs(_gui[2]) do
            tween:Play()
        end
    end

    -- after 5 seconds, play out tweens. wait for them to finish and fire Finished
    local finished = Instance.new("BindableEvent")
    task.delay(5, function()
        for _, _gui in pairs(guis) do
            for _, tween in pairs(_gui[3]) do
                tween:Play()
            end
        end
        task.wait(1)
        finished:Fire()
    end)

    return finished
end

local winMessages = {{"Destroyed", 30}, {"Killed", 50}, {"Sacued", 16}, {"Fell in love with", 4}}
local winNumbers = {} local last for i, v in pairs(winMessages) do if last then winNumbers[i] = {last+1, v[2]} else winNumbers[i] = {i, v[2]} end last = v[2] end

function _1v1:GetRandomWinMessage()
    local r = math.random(1, 100)
    for winIndex, v in pairs(winNumbers) do
        if r > v[1] and r < v[2] then
            return winMessages[winIndex][1]
        end
    end
end

gui._1v1 = _1v1
return gui
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)
local diedMainEvent = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local RunService = game:GetService("RunService")
local FadeScreenOut = require(Framework.Module.lib.m_fadescreenout)

local _1v1 = {
    minimumPlayers = 2,
    maximumPlayers = 2,

    roundLength = 60,
    roundAmountToWin = 7,
    
    overtimeEnabled = true,
    overtimeRoundAmountToWin = 3,

    startWithBarriers = true,
    barrierLength = 3,

    weaponPool = {
        primary = {"AK103", "ACR"},
        primary_light = {"Vityaz"},
        secondary_light = {"Glock17"},
        secondary = {"Deagle"},
    },

    respawnsEnabled = false,
    playerDataEnabled = true,
    botsEnabled = false,

    var = {currentRound = 1},
    playerdata = {},
    players = {},
    buymenu = nil
}

-- Base Functions

function _1v1:Start()
    print("Gamemode " .. self.Name .. " started!")

    -- init current players (self.players)
    for _, player in pairs(Players:GetPlayers()) do
        self:InitPlayerData(player)
    end

    -- init player added connection
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:InitPlayerData(player)
    end)

    -- wait for min
    if #self.players < (self.minimumPlayers or 1) then
        self:WaitForMinimumPlayers()
    end

    -- init playerdata removing connection
    self.playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        if self.playerdata[player.Name] then
            pcall(function()
                for i, v in pairs(self.playerdata[player.Name].connections) do
                    v:Disconnect()
                end
            end)
            self.playerdata[player.Name] = nil
            self.players[player.Name] = nil
        end
    end)

    -- init player died registration connection
    if self.playerDiedRegisterConn then self.playerDiedRegisterConn:Disconnect() end
    self.playerDiedRegisterConn = diedMainEvent.OnServerEvent:Connect(function(player)
        self:Died(player)
    end)

    -- init player round gui
    self:InitPlayerGuiAll()

    -- fade screen in
    self:FadeScreenInAll()

    task.wait(1)

    self:RoundStart()
end

function _1v1:Stop()

    -- set status
    self.status = "dead"

    -- disconnect connections
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    if self.isWaiting then
        --coroutine.yield(self.waitingThread)
        return
    end

    -- stop queue service
    --QueueService:Stop()

    -- remove all weapons and abilities
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()

    -- unload all characters
    for i, v in pairs(Players:GetPlayers()) do
        v.Character.Humanoid:TakeDamage(1000)
        v.Character = nil
    end

    -- clear temps (destroy grenades, bullets, etc)
    for i, v in pairs(workspace.Temp:GetChildren()) do
        v:Destroy()
    end

    -- destroy bots
    for i, v in pairs(CollectionService:GetTagged("Bot")) do
        task.spawn(function()
            v.Humanoid:TakeDamage(1000)
            task.wait(0.1)
            v:Destroy()
        end)
    end

    self.var.finished:Destroy()

    task.wait(0.1)
    print('Gamemode Lobby Stopped')
end

function _1v1:GameEnd(winner, loser)
    
    -- game over screen
    -- update stats on DataStore

end

-- Round Functions

function _1v1:RoundStart()

    print('Round Starting!')

    -- unload all characters sanity
    self:UnloadAllCharacters()
    task.wait(1)

    -- prepare map
    -- todo: reset all opened doors, etc
    for i, v in pairs(workspace.Temp:GetChildren()) do
        v:Destroy()
    end

    -- load all characters
    self:LoadAllCharacters()

    -- fade screens out
    self:FadeScreenOutAll()

    -- start barrier timer (yields)
    self:RoundStartBarriers()

    -- create finished event
    if not self.var.finished then
        self.var.finished = Instance.new("BindableEvent", game:GetService("ReplicatedStorage").temp)
    end

    -- start round timer
    self:RoundStartTimer()

    -- listen for death events
    self:RoundStartListenForDeath()

    -- register round finished event
    self.var.finished.Event:Once(function(result, winner, loser) -- result: "RoundOverWon", "RoundOverTimer", "GameOver"
        self:RoundEnd(result, winner, loser)
    end)

    print('Round started!!')

end

function _1v1:RoundEnd(result, winner, loser) -- result: RoundOverWon or RoundOverTimer

    -- stop timer
    self.var.roundTimer:Disconnect()

    task.spawn(function()
        self:StopGuiTimerAll()
    end)

    -- let player run around for a sec
    task.wait(3)

    -- fade screens
    self:FadeScreenInAll()

    -- unload all characters
    self:UnloadAllCharacters()

    -- increment round
    self.var.currentRound += 1

    if result == "RoundOverWon" then

        -- calculate stats
        self.playerdata[winner.Name].wins += 1
        self.playerdata[loser.Name].deaths += 1

        task.spawn(function()
            self:UpdateGuiScoreAll()
        end)

        -- decide if overtime
        if self.playerdata[winner.Name].wins == self.roundAmountToWin - 1 and self.playerdata[loser.Name].wins == self.roundAmountToWin - 1 then
            -- overtime
            return
        end

        if self.playerdata[winner.Name].wins >= self.roundAmountToWin then
            -- player won!
            return self:GameEnd(winner, loser)
        end

        return self:RoundStart()
    elseif result == "RoundOverTimer" then
        -- idk
    end
end

function _1v1:RoundStartBarriers()
    local barr = self.Location.Barriers:Clone()
    barr.Parent = workspace

    task.spawn(function()
        self:StartGuiTimerAll(self.barrierLength)
    end)

    task.wait(self.barrierLength)

    barr:Destroy()
end

function _1v1:RoundStartTimer()
    print('timer starting')

    -- timer shit
    self.var.roundTimerCurrentTime = 0
    self.var.roundTimerEndTime = tick() + self.roundLength

    task.spawn(function()
        self:StartGuiTimerAll(self.roundLength)
    end)
    
    local ignore = false

    self.var.roundTimer = RunService.Heartbeat:Connect(function()

        if ignore then return end

        -- timer reached
        if tick() >= self.var.roundTimerEndTime then
            self.var.finished:Fire("RoundOverTimer")
            ignore = true
            return
        end
        
        -- time second update
        local currsec = math.floor(self.var.roundTimerEndTime - tick())
        if self.var.roundTimerCurrentTime < currsec then
            self.var.roundTimerCurrentTime = currsec
            --TODO: fire second changed event to clients for GUI
        end

    end)

    print('timer started')
end

function _1v1:RoundStartListenForDeath()
    self.var.deathListener = diedMainEvent.OnServerEvent:Once(function(killed, killer)

        if not killer or killed == killer then
            -- player comitted suicide
            self.var.finished:Fire("RoundOverWon", self:GetOtherPlayer(killed), killed)
            return
        end

        self.var.finished:Fire("RoundOverWon", killer, killed)
        return
    end)
end

function _GetRandomWeaponsIn(tab)
    local weapons = {}
    for i, v in pairs(tab) do
        table.insert(weapons, string.lower(v[math.random(1,#v)]))
    end
    return weapons
end

function _1v1:RoundStartGetPlayerContent() -- return: spawns, weapons

    local spawns = {}
    local r1 = math.round(math.random(1000,2000)/1000)
    spawns[1] = self.Location.Spawns["Spawn"..tostring(r1)]
    spawns[2] = self.Location.Spawns["Spawn"..tostring(r1 == 1 and 2 or 1)]

    -- get weapon based on round
    local weapons
    
    if self.var.currentRound == 1 then
        weapons = _GetRandomWeaponsIn({self.weaponPool.secondary_light})
    elseif self.var.currentRound == 2 then
        weapons = _GetRandomWeaponsIn({self.weaponPool.secondary})
    elseif self.var.currentRound == 3 then
        weapons = _GetRandomWeaponsIn({self.weaponPool.primary_light, self.weaponPool.secondary})
    else
        weapons = _GetRandomWeaponsIn({self.weaponPool.primary, math.random(1,2) == 1 and self.weaponPool.secondary or self.weaponPool.secondary_light})
    end

    local abilities = {"Dash"}
    table.insert(abilities, math.round(math.random(1000,2000)/1000) == 1 and "LongFlash" or "Molly")

    return spawns, weapons, abilities
end

-- Player Functions

function _1v1:InitPlayerData(player)
    self.playerdata[player.Name] = {deathCameraScript = false, wins = 0, deaths = 0, totalDamage = 0, roundDamage = 0, deathConnection = false}
    if not table.find(self.players, player) then table.insert(self.players, player) end
end

function _1v1:LoadAllCharacters()
    local RandomizedSpawns, RoundWeapons, RoundAbilities = self:RoundStartGetPlayerContent()
    for i, v in pairs(self.players) do
        self:SpawnPlayer(v, RandomizedSpawns[i].CFrame, RoundWeapons, RoundAbilities)
    end
end

function _1v1:UnloadAllCharacters()
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()
    for i, v in pairs(self.players) do
        if self.playerdata[v.Name].deathConnection then
            self.playerdata[v.Name].deathConnection:Disconnect()
        end

        -- these next two if statements must be in this order
        if self.playerdata[v.Name] and self.playerdata[v.Name].deathCameraScript then
            self.playerdata[v.Name].deathCameraScript:WaitForChild("Destroy"):FireClient(v)
            Debris:AddItem(self.playerdata[v.Name].deathCameraScript, 2)
        end
        if v.Character then
            if v.Character.Humanoid then v.Character.Humanoid:TakeDamage(1000) v.Character = nil end
        end
    end
end

function _1v1:SpawnPlayer(player, locationCFrame, weapons, abilities)
    task.spawn(function()
        print('spawning player ' .. player.Name)
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
        end

        player:LoadCharacter()
        task.wait(0.1)
        
        local hum = player.Character:WaitForChild("Humanoid")
        player.Character.Humanoid.Health = 100
    
        -- teleport player to spawn
        player.Character.PrimaryPart.Anchored = true
        player.Character:SetPrimaryPartCFrame(locationCFrame)
        player.Character.PrimaryPart.Anchored = false
        
        -- add abilities
        for i, v in pairs(abilities) do
            Ability.Add(player, v)
        end

        -- add weapons
        for i, v in pairs(weapons) do
            Weapon.Add(player, v, false)
        end
        Weapon.Add(player, "Knife", true)
    
        local conn
        conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
            if self.status ~= "running" then conn:Disconnect() return end
            if hum.Health <= 0 then self:Died(player) conn:Disconnect() print('died player ' .. player.Name) return end
        end)

        self.playerdata[player.Name].deathConnection = conn
        print('spawned player ' .. player.Name)
    end)
end

function _1v1:WaitForMinimumPlayers()
    repeat
        task.wait(0.5)
    until #self.players >= self.minimumPlayers
end

function _1v1:GetOtherPlayer(player)
    for i, v in pairs(self.players) do
        if v:IsA("Player") and v ~= player then return v end
    end
    return false
end

function _1v1:GetTotalPlayerCount()
    local _count = 0
    for i, v in pairs(self.playerDataEnabled and self.playerdata or Players:GetPlayers()) do
        if v then _count += 1 end
    end
    return _count
end

-- Player Gui functions

function _1v1:InitPlayerGuiAll()
    for i, v in pairs(self.players) do
        local _bar = self.Location.GamemodeBar:Clone()
        self.Location.gamemodeGuiMain:Clone().Parent = _bar

        local enemyobj = Instance.new("ObjectValue")
        enemyobj.Name = "EnemyObject"
        enemyobj.Value = self:GetOtherPlayer(v)
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
function _1v1:FadeScreenInAll()
    if not self.var.fades then self.var.fades = {} end -- save so we can fade in during spawn
    for i, v in pairs(self.players) do
        table.insert(self.var.fades, FadeScreenOut(v))
        self.var.fades[#self.var.fades] = self.var.fades[#self.var.fades] :: FadeScreenOut.Fade -- just for type signature
        self.var.fades[#self.var.fades].In:Play()
    end
end

-- Remove black screen
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

-- Died

function _1v1:Died(player)

    self:DiedCamera(player)
    self:DiedGui(player)

    task.spawn(function()
        Weapon.ClearPlayerInventory(player)
        Ability.ClearPlayerInventory(player)
    end)

end

function _1v1:DiedCamera(player)
    local killer = player.Character:FindFirstChild("DamageTag") and player.Character.DamageTag.Value or player
    local camerac = self.objects.deathCameraScript:Clone()
    camerac:WaitForChild("killerObject").Value = killer
    camerac.Parent = player.Character
    self.playerdata[player.Name].deathCameraScript = camerac
end

function _1v1:DiedGui()
end

return _1v1
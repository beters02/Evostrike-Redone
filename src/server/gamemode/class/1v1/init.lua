local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)
local diedMainEvent = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local RunService = game:GetService("RunService")
local EvoMM = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("EvoMMWrapper"))
local MapIDs = require(game:GetService("ServerScriptService"):WaitForChild("main"):WaitForChild("storedMapIDs"))
local PlayerStats = require(Framework.shm_playerstats.Location)
local ServerPlayerData = require(game:GetService("ServerScriptService").playerdata.m_serverPlayerData)
local EvoPlayer = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("EvoPlayer"))

local _1v1 = {
    minimumPlayers = 2,
    maximumPlayers = 2,

    roundLength = 60,
    roundAmountToWin = 7,
    
    overtimeEnabled = true,
    overtimeRoundAmountToWin = 3,

    startWithBarriers = true,
    barrierLength = 3,
    canQueue = true,

    shieldEnabled = true,
    startingShield = 50,
    startingHelmet = true,
    startingHealth = 100,

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

-- Inherit doGui functions on require
local doGui = require(game:GetService("ServerScriptService").gamemode.fc_doGui)
local TeleportService = game:GetService("TeleportService")
for i, v in pairs(doGui._1v1) do
    _1v1[i] = v
end

-- Base Functions

function _1v1:Start()
    print("Gamemode " .. self.Name .. " started!")

    -- Set IsGameServer
    -- Players can rejoin in this gamemode.
    EvoMM.MatchmakingService:SetIsGameServer(true, true)

    -- init current players (self.players)
    for _, player in pairs(Players:GetPlayers()) do
        self:InitPlayerData(player)
    end

    -- wait for min
    if #self.players < self.minimumPlayers or 1 then
        if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
        self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
            self:InitPlayerData(player)
            self:WaitingScreen(player)
        end)
        self:WaitingScreenAll()
        self:WaitForMinimumPlayers()        
    end

    self:RemoveWaitingScreenAll(false)

    self.playerAddedConnection = Players.PlayerAdded:Connect(function()
        -- spectate
        -- for now we'll just set their camera position to somewhere on top of the map
    end)

    self.playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        if self.playerdata[player.Name] then

            -- update stats

            -- remove playerdata
            pcall(function()
                for i, v in pairs(self.playerdata[player.Name].connections) do
                    v:Disconnect()
                end
            end)

            self.playerdata[player.Name] = nil
            self:RemovePlayerFromPlayers(player)
        end

        if #self.players > 0 and self.players < self.minimumPlayers then
            -- stop 1v1 and restart with "waiting for players"
            task.delay(2, function()
                self:Start()
            end)
            self:Stop()
        elseif self.players == 0 then
            -- stop and do not restart, server will automatically be shut down
            self:Stop()
        end

    end)

    -- init player died registration connection
    -- disconnect the previous playerDied if necessary
    if self.playerDiedRegisterConn then self.playerDiedRegisterConn:Disconnect() end
    self.playerDiedRegisterConn = diedMainEvent.OnServerEvent:Connect(function(player)
        self:Died(player)
    end)

    -- init player round gui
    self:InitPlayerGuiAll()

    -- This will actually already be done during the waiting phase,
    -- i'll leave it here just in case it breaks something
    --[[fade screen in
    --self:FadeScreenInAll()]]

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
        -- return ???
        self.isWaiting = false
    end
    
    EvoMM.MatchmakingService:SetIsGameServer(false, false)

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

    EvoMM.MatchmakingService:SetIsGameServer(false, false)

    self:UnloadAllCharacters()

    task.delay(3, function()
        TeleportService:TeleportAsync(MapIDs.GetMapId("lobby"), self.players)
        print('Players teleported to Lobby. Destroying server in 5 seconds.')
        task.delay(5, function()
            self:Stop()
        end)
    end)

    -- update stats on DataStore
    local currmap = MapIDs.GetCurrentMap()

    -- winner
    local function updateWinner()
        local incrementData = {
            wins = 1,
            matchesPlayed = 1,
            kills = self.playerdata[winner.Name].wins,
            deaths = self.playerdata[winner.Name].deaths,
            damage = self.playerdata[winner.Name].totalDamage, 
        }

        PlayerStats.IncrementAllValuesInKey(winner, currmap, incrementData) -- update map stats
        PlayerStats.IncrementAllValuesInKey(winner, "global", incrementData) -- update "global" (total) stats
    end

    task.spawn(function()
        local succ, err = pcall(updateWinner)
        if not succ then
            local count = 1
            repeat
                succ, err = pcall(updateWinner)
                count += 1
            until succ or count > 3
            if not succ then warn("Could not set PlayerData " .. winner.Name .. " " .. tostring(err)) end
        end
    end)

    -- loser
    local function updateLoser()
        local incrementData = {
            losses = 1,
            matchesPlayed = 1,
            kills = self.playerdata[loser.Name].wins,
            deaths = self.playerdata[loser.Name].deaths,
            damage = self.playerdata[loser.Name].totalDamage,
        }

        PlayerStats.IncrementAllValuesInKey(loser, currmap, incrementData) -- update map stats
        PlayerStats.IncrementAllValuesInKey(loser, "global", incrementData) -- update "global" (total) stats
    end

    task.spawn(function()
        local succ, err = pcall(updateLoser)
        if not succ then
            local count = 1
            repeat
                succ, err = pcall(updateLoser)
                count += 1
            until succ or count > 3
            if not succ then warn("Could not set PlayerData " .. loser.Name .. " " .. tostring(err)) end
        end
    end)
end

-- Round Functions

function _1v1:RoundStart()

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
    --task.wait(3)

    local roundWonPostPeriodFinished = self:RoundWonScreen(winner, loser)
    roundWonPostPeriodFinished.Event:Wait()

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

function _GetRoundShield(self)
    local shield, helmet = self.startingShield, self.startingHelmet
    if self.var.currentRound == 1 then
        shield, helmet = 0, false
    elseif self.var.currentRound == 2 then
        shield, helmet = 50, false
    end
    return {shield = shield, helmet = helmet}
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

    return spawns, weapons, abilities, _GetRoundShield(self)
end

-- Player Functions

function _1v1:InitPlayerData(player)
    self.playerdata[player.Name] = {deathCameraScript = false, wins = 0, deaths = 0, totalDamage = 0, roundDamage = 0, deathConnection = false}
    if not table.find(self.players, player) then table.insert(self.players, player) end
end

function _1v1:RemovePlayerFromPlayers(player)
    local fi = table.find(self.players)
    if fi then
        table.remove(fi, self.players)
    else
        for i, v in pairs(self.players) do
            if v == player then fi = true self.players[i] = nil break end
        end
    end
    return fi or false, warn("Player not found")
end

function _1v1:LoadAllCharacters()
    local RandomizedSpawns, RoundWeapons, RoundAbilities, RoundShield = self:RoundStartGetPlayerContent()
    for i, v in pairs(self.players) do
        self:SpawnPlayer(v, RandomizedSpawns[i].CFrame, RoundWeapons, RoundAbilities, RoundShield)
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

function _1v1:SpawnPlayer(player, locationCFrame, weapons, abilities, shieldTable)
    task.spawn(function()
        print('spawning player ' .. player.Name)
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
        end

        player:LoadCharacter()
        task.wait(0.1)
        
        local hum = player.Character:WaitForChild("Humanoid")
        player.Character.Humanoid.Health = self.startingHealth
        EvoPlayer:SetShield(player.Character, shieldTable.shield)
        EvoPlayer:SetHelmet(player.Character, shieldTable.helmet)
    
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
        if type(v) == "table" then return v end
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
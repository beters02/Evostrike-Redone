export type RoundEndedResult = "teamDied" | "timer" | "bombDefused" | "bombExploded"
export type GTeam = "attacker" | "defender"

-- CollectionService
-- DestroyOnRoundEnd
-- DestroyOnGameEnd
-- DestroyOnRoundStart

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tags = require(Framework.Module.lib.fc_tags)
local Tables = require(Framework.Module.lib.fc_tables)
local Random = require(Framework.Module.lib.fc_random)
local Strings = require(Framework.Module.lib.fc_strings)
local Player = require(Framework.Module.EvoPlayer)
local PlayerDiedEvent = Framework.Module.EvoPlayer.Events.PlayerDiedRemote
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local BotService = require(Framework.Service.BotService)
local GamemodeEvents = ReplicatedStorage.GamemodeEvents

local events = {RoundEnded = true, BombPlanted = true, BombDefused = true} -- Temporary Bindable Events created for Gamemode
local options = require(script:WaitForChild("GameOptions"))
local spawns = script:WaitForChild("Spawns")
local buymenu = require(script:WaitForChild("BuyMenu"))

local gamedata = require(script:WaitForChild("GameData"))
local playerdata = require(script:WaitForChild("PlayerData"))
local teamdata = require(script:WaitForChild("TeamData"))

function Init()

    -- init events
    for i, _ in pairs(events) do
        events[i] = Instance.new("BindableEvent")
        events[i].Name = i
    end

    -- connect buy menu
    buymenu:init()

    -- init players
    for _, v in pairs(Players:GetPlayers()) do
        init_player(v)
    end

    -- force start command connection
    local forceStart = false
    local forceStartConn = GamemodeEvents.Game.ForceStart.OnServerEvent:Once(function()
        forceStart = true
        gamedata.wasForceStart = true
    end)

    -- wait for players (or forcestart)
    if playerdata._count < 4 then
        local waitconn = Players.PlayerAdded:Connect(function(player)
            init_player(player)
        end)
        repeat task.wait() until playerdata._count >= 4 or forceStart
        waitconn:Disconnect()
    end

    if forceStart then
        -- init bots
        local botAmnt = 4 - playerdata._count
        for i = 1, botAmnt do
            playerdata._bots["Bot"..tostring(i)] = Tables.clone(playerdata._def)
        end
    end

    -- assign teams & init buy menus
    local index = 0
    local teams = {"attacker", "attacker", "defender", "defender"}
    teams = Random.shuffle(teams)
    for plrName, _ in pairs(playerdata._stored) do
        index += 1
        teamdata[teams[index]].players[plrName] = {plr = get_player(plrName), alive = true}
        playerdata._stored[plrName].team = teams[index]
    end
    if forceStart then
        for botName, _ in pairs(playerdata._bots) do
            index += 1
            teamdata[teams[index]].players[botName] = {plrName = botName, alive = true}
            playerdata._bots[botName].team = teams[index]
        end
    end
    for plrName, _ in pairs(playerdata._stored) do
        local yourTeam = playerdata._stored[plrName].team
        local enemyTeam = yourTeam == "attacker" and "defender" or "attacker"
        init_player_hud_final(get_player(plrName), teams[index], teamdata[yourTeam], teamdata[enemyTeam])
    end
    

    -- disconnect remaining
    forceStartConn:Disconnect()

    Start()
end

function Start()
    print('Game Starting')

    local PlayerJoinedConnection = Players.PlayerAdded:Connect(function(player)
        -- kick player or send to spectate
        player:Kick("Cannot join full game.")
    end)

    local DeathConnection = PlayerDiedEvent.OnServerEvent:Connect(function(died, killer, weaponUsed)
        if gamedata.status == "inactive" then
            return
        end
        PlayerDied(died, killer, weaponUsed)
    end)

    local BotDeathConnection = false
    if gamedata.wasForceStart then
        BotDeathConnection = Framework.Service.BotService.Remotes.BotDiedBindable.Event:Connect(function(died, killer, weaponUsed)
            BotDied(died, killer, weaponUsed)
        end)
    end

    local BombPlantedConnection = GamemodeEvents.Bomb.Planted.OnServerEvent:Connect(function(player)
        if gamedata.status == "inactive"
        or gamedata.bombStatus ~= "planting" then
            return
        end

        gamedata.bombStatus = "planted"
        events.BombPlanted:Fire(player)
    end)

    local CancelBombPlantConnection = GamemodeEvents.Bomb.CancelPlant.OnServerEvent:Connect(function(player)
        if gamedata.status == "inactive"
        or gamedata.bombStatus ~= "planting" then
            return
        end

        gamedata.bombStatus = "inactive"
    end)

    local BombDefusedConnection = GamemodeEvents.Bomb.Defused.OnServerEvent:Connect(function(player)
        if gamedata.status == "inactive"
        or gamedata.bombStatus ~= "defusing" then
            return
        end

        gamedata.bombStatus = "inactive"
        RoundEnd("bombDefused")
    end)

    GamemodeEvents.Bomb.BeginPlant.OnServerInvoke = function(player)
        if gamedata.status == "inactive"
        or not player.Character:FindFirstChild("Tool_Bomb")
        or gamedata.bombStatus ~= "inactive" then
            return false
        end
        -- check if player is in bomb plant radius
        gamedata.bombStatus = "planting"
        return true
    end

    GamemodeEvents.Bomb.BeginDefuse.OnServerInvoke = function(player)
        if gamedata.status == "inactive"
        or gamedata.bombStatus ~= "inactive" then
            return false
        end
        -- check if player is in bomb defuse radius
        gamedata.bombStatus = "defusing"
    end

    RoundStart()
end

function End(winningTeam, losingTeam) -- Called when Gamemode ends naturally
    gamedata.status = "inactive"
    task.wait(3)
    Tags.DestroyTagged("DestroyOnGameEnd")
end

function Stop() -- Forcefully Stop Gamemode
    gamedata.status = "inactive"
    Tags.DestroyTagged("DestroyOnGameEnd")
end

--

--@summary Spawn Players, Start round timer, Connect BombPlanted BindableEvent.
function RoundStart()
    gamedata.status = "active"

    Tags.DestroyTagged("DestroyOnRoundStart")

    -- spawn players
    SpawnTeam("attacker")
    SpawnTeam("defender")

    -- buy menu & barrier timer
    local buyMenuTimeLeft = options.BUY_MENU_CAN_PURCHASE_LENGTH
    local buyMenuLengthConnection
    gamedata.canBuy = true
    GamemodeEvents.HUD.StartTimer:FireAllClients(buyMenuTimeLeft)
    buyMenuLengthConnection = RunService.Heartbeat:Connect(function(dt)
        buyMenuTimeLeft -= dt
        if buyMenuTimeLeft <= 0 then
            -- destroy barriers
            gamedata.canBuy = false
            buyMenuLengthConnection:Disconnect()
            return
        end
    end)

    repeat task.wait() until not gamedata.canBuy

    -- start round timer
    local ended = false
    local bombPlanted = false
    local roundTimeLeft = options.ROUND_LENGTH
    local bombPlantedConnection
    local roundTimerConnection
    local roundEndedConnection
    GamemodeEvents.HUD.StartTimer:FireAllClients(roundTimeLeft)
    roundTimerConnection = RunService.Heartbeat:Connect(function(dt)
        if ended then return end
        roundTimeLeft -= dt
        if roundTimeLeft <= 0 then
            ended = true
            RoundEnd(bombPlanted and "bombExploded" or "timer") -- Fires events.RoundEnded which clears all connections.
        end
    end)

    -- set timeLeft to bombTime when bomb is planted
    bombPlantedConnection = events.BombPlanted.Event:Once(function()
        bombPlanted = true
        roundTimeLeft = options.BOMB_PLANT_ROUND_LENGTH
    end)

    -- clear all connections
    roundEndedConnection = events.RoundEnded.Event:Once(function()
        roundTimerConnection:Disconnect()
        bombPlantedConnection:Disconnect()
        roundEndedConnection:Disconnect()
        buyMenuLengthConnection:Disconnect()
    end)
end

--@summary Fires RoundEnded BindableEvent, gets winners & losers, ends game or starts new round.
function RoundEnd(result: RoundEndedResult, ...)
    print('Round Ended!')

    local winningTeam, losingTeam
    events.RoundEnded:Fire(result)
    gamedata.status = "inactive"

    if result == "teamDied" then
        winningTeam, losingTeam = ...
    elseif result == "timer" or result == "bombDefused" then
        winningTeam, losingTeam = "defenders", "attackers"
    elseif result == "bombExploded" then
        winningTeam, losingTeam = "attackers", "defenders"
    end

    teamdata[winningTeam].score += 1
    hud_change_round(winningTeam, teamdata[winningTeam].score)
    print('Changed round!')

    -- do post round GUI stuff
    task.wait(3)

    Tags.DestroyTagged("DestroyOnRoundEnd")
    destroy_all_players()

    -- if not overtime and
    if teamdata[winningTeam].score == options.MAX_ROUND_WIN - 1 and teamdata[losingTeam].score == options.MAX_ROUND_WIN - 1 then
        -- overtime
    elseif teamdata[winningTeam].score >= options.MAX_ROUND_WIN then
        End(winningTeam, losingTeam)
    else
        RoundStart()
    end
end

function PlayerDied(died, killer, weaponUsed)
    if not Players[died.Name] then
        return
    end

    local alivePlayersTeam = playerdata._get(killer, "team")
    local deadPlayersTeam = playerdata._get(died, "team")

    if alivePlayersTeam == deadPlayersTeam then
        playerdata._dec(killer, "kills", 1)
        playerdata._dec(killer, "money", options.KILLED_TEAMMATE_MONEY_DEC)
        -- fire SetMoney Event
    else
        local moneyAdd = options.Enum.KILL_MONEY_GAINED[weaponUsed] or options.Enum.KILL_MONEY_GAINED.default
        playerdata._inc(killer, "kills", 1)
        playerdata._inc(killer, "money", moneyAdd)
        -- fire AddMoney HUD Event
    end
    
    playerdata._inc(died, "deaths", 1)
    playerdata._set(died, "inventory", Tables.clone(playerdata._def.inventory))
    teamdata[deadPlayersTeam].players[died.Name].alive = false

    if not check_team_alive(deadPlayersTeam) then
        RoundEnd("teamDied", alivePlayersTeam, deadPlayersTeam)
    end
end

function BotDied(died, killer, weaponUsed)
    local alivePlayersTeam = playerdata._get(killer, "team")
    local deadPlayersTeam = playerdata._bots[died.Name].team
    if alivePlayersTeam == deadPlayersTeam then
        playerdata._dec(killer, "kills", 1)
        playerdata._dec(killer, "money", options.KILLED_TEAMMATE_MONEY_DEC)
        -- fire SetMoney Event
    else
        local moneyAdd = options.Enum.KILL_MONEY_GAINED[weaponUsed] or options.Enum.KILL_MONEY_GAINED.default
        playerdata._inc(killer, "kills", 1)
        playerdata._inc(killer, "money", moneyAdd)
        -- fire AddMoney HUD Event
    end

    playerdata._bots[died.Name].deaths += 1
    teamdata[deadPlayersTeam].players[died.Name].alive = false

    if not check_team_alive(deadPlayersTeam) then
        RoundEnd("teamDied", alivePlayersTeam, deadPlayersTeam)
    end
end

function SpawnTeam(team: GTeam)
    local counter = 0
    local _spawns = Random.shuffle(spawns[Strings.firstToUpper(team)]:GetChildren())
    for plrName, _ in pairs(teamdata[team].players) do
        counter += 1
        teamdata[team].players[plrName].alive = true

        if gamedata.wasForceStart and not playerdata._stored[plrName] then
            SpawnBot(plrName, _spawns[counter].CFrame)
            continue
        end

        local plr = get_player(plrName)
        local pd = playerdata._get(plr)
        local cf = _spawns[counter].CFrame

        plr:LoadCharacter()

        task.spawn(function()
            
            local char = plr.Character or plr.CharacterAdded:Wait()
            char:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 2, 0)

            for _, wep in pairs(pd.inventory.weapons) do
                if wep then WeaponService:AddWeapon(plr, wep) end
            end
            WeaponService:AddWeapon(plr, "knife", true)

            for _, abl in pairs(pd.inventory.abilities) do
                if abl then AbilityService:AddAbility(plr, abl) end
            end
        end)
    end
end

function SpawnBot(botName, spawnCF)
    local cf = spawnCF + Vector3.new(0,2,0)
    playerdata._bots[botName].plr = BotService:AddBot({Name = botName, SpawnCFrame = cf, Respawn = false})
end

--

--@summary Add Player to PlayerData and Give HUD Module
function init_player(player)
    if not playerdata._get(player) then
        playerdata._add(player)

        task.spawn(function()
            init_player_hud_first(player)
        end)
    end
end

function init_player_hud_first(player)
    local hudContainer = Instance.new("ScreenGui", player.PlayerGui)
    hudContainer.ResetOnSpawn = false
    hudContainer.Name = "Container_2v2"

    local hudClone = script:WaitForChild("HUD"):Clone()
    hudClone.Name = "HUD_2v2"
    CollectionService:AddTag(hudClone, "DestroyOnGameEnd")

    -- add DestroyOnGameEnd to HUDScript
    for _, v in pairs(hudClone:WaitForChild("Guis"):GetChildren()) do
        CollectionService:AddTag(v, "DestroyOnGameEnd")

        -- add DestroyOnGameEnd to HUDScript Children
        for _, c in pairs(v:GetChildren()) do
            CollectionService:AddTag(c, "DestroyOnGameEnd")
        end
    end

    hudClone.Parent = hudContainer
end

--@summary Init a player's BuyMenu gui after theyve been added to a team, and finish HUD initialization.
function init_player_hud_final(player, team, yourTeamdata, enemyTeamdata)
    local buyMenuGui = player.PlayerGui["Container_2v2"]["HUD_2v2"].Guis.BuyMenu.Gui
    buymenu:initPlayerBuyMenu(buyMenuGui, team)

    local yourTeamNames = {}
    local enemyTeamNames = {}

    local counter = 0
    for _, v in pairs(enemyTeamdata.players) do
        counter += 1
        enemyTeamNames[counter] = v.plr and v.plr.Name or v.plrName
    end
    for _, v in pairs(yourTeamdata.players) do
        if v.plr and v.plr == player then
            continue
        end
        yourTeamNames[1] = v.plr and v.plr.Name or v.plrName
    end

    GamemodeEvents.HUD.START:FireClient(player, team, yourTeamNames, enemyTeamNames)
end

--@summary Get Player by Name
function get_player(plrName)
    return playerdata._stored[plrName] and playerdata._stored[plrName].plr
end

function check_team_alive(team)
    for _, v in pairs(teamdata[team].players) do
        if v.alive then
            return true
        end
    end
    return false
end

function destroy_all_players()
    for _, v in pairs(playerdata._stored) do
        v.Character = nil
    end
    if gamedata.wasForceStart then
        for _, v in pairs(playerdata._bots) do
            v.plr:Destroy()
        end
    end
end

--@summary Correctly Fire ChangeRound Event
function hud_change_round(teamName, new)
    for _, v in pairs(playerdata._stored) do
        if teamName == v.team then
            GamemodeEvents.HUD.ChangeRound:FireClient(v.plr, new)
        else
            GamemodeEvents.HUD.ChangeRound:FireClient(v.plr, false, new)
        end
    end
end

--

Init()
-- [[ TEMP CLASS FUNCTIONS ]]
--[[
    
]]

--[[
    GameService will handle the majority of the core functionality for gamemodes and maps

    Handles:
        PlayerData
        Timer
        Rounds
        Round and Game end conditions
    
    Calls:
        Gamemode:Start()
        Gamemode:RoundStart()
        Gamemode:RoundEnd()
        Gamemode:End()
        Gamemode:InitPlayer()
        Gamemode:PlayerAdded()
        Gamemode:PlayerDied(died, killer, killNotRegistered)
        Gamemode:PlayerRemoved()
        Gamemode:PlayerJoinedDuringRound()
        Gamemode:SpawnPlayer()  -- Only when player joined during round and SPAWN_ON_JOIN.

]]

--[[ SERVICE CONFIG ]]
local DEFAULT_GAMEMODE = "Deathmatch"

--[[ SERVICES ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- [[ MODULES ]]
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerDiedEvent = Framework.Module.EvoPlayer.Events.PlayerDiedRemote
local GM_PlayerData = require(script:WaitForChild("PlayerData"))
local Table = require(Framework.Module.lib.fc_tables)
local LGamemode = script:WaitForChild("Gamemode")
local CGamemode = require(LGamemode)
local EvoMM = require(Framework.Module.EvoMMWrapper)
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local GamemodeService2 = require(Framework.Service.GamemodeService2)
local RequestSpawnEvent = Framework.Service.GamemodeService2.RequestSpawn
local GameServiceRemotes = script:WaitForChild("Remotes")

--[[ MODULE ]]
local GameService = {
    CurrentGamemode = false,
    CurrentMap = false,
    GameOptions = Table.clone(CGamemode.GameOptions),
    PlayerData = false,
    TeamData = false,

    StartTime = 0,
    TimeElapsed = 0,
    GameStatus = "LOADING", -- STARTED, ENDED
    RoundStatus = "LOADING", -- STARTED, ENDED
    CurrentRound = 0,

    Connections = {},
}
local Types = require(script:WaitForChild("Types"))

--[[ CALLING FUNC ]]

-- Call a Function from the CurrentGamemode Class, will automatically push service variable.
function gmCall(func: string, ...: any)
    return GameService.CurrentGamemode[func](GameService.CurrentGamemode, GameService, ...)
end
--

-- [[ GET ]]
function getGMod(gamemode: string)
    return LGamemode:FindFirstChild(gamemode)
end

function getRoundScore(plr)
    if GameService.TEAMS_ENABLED then
        local team = getPlayersTeam(plr)
        local teamObj = GameService.Teams[team]
        return GameService.TeamData:Get(teamObj, "score")
    end

    return GameService.PlayerData:Get(plr, "score")
end

function getPlayersTeam(plr)
    return GameService.PlayerData:Get(plr, "team")
end
--

-- [[ SET ]]

function incRoundScore(plr: Player)
    if GameService.TEAMS_ENABLED then
        local team = getPlayersTeam(plr)
        local teamObj = GameService.Teams[team]
        GameService.TeamData:Increment(teamObj, "score", 1)
        return GameService.TeamData:Get(teamObj, "score")
    end

    GameService.PlayerData:Increment(plr, "score", 1)
    return GameService.PlayerData:Get(plr, "score")
end

-- [[ MAIN ]]

-- Module Initialization
function GameService.Initialize()
    GameService.GameStatus = "LOADING"

    -- wait for player to join
    local player
    local players = Players:GetPlayers()
    if #players == 0 then
        player = Players.PlayerAdded:Wait()
    else
        player = players[1]
    end

    -- get current gamemode from player joined, or default gamemode
    local teleData = player:GetJoinData().teleportData
    local mmGameData = EvoMM.MatchmakingService:GetUserData(player)
    local requestedGamemode = DEFAULT_GAMEMODE

    if teleData and teleData.RequestedGamemode then
        requestedGamemode = teleData.RequestedGamemode
    elseif mmGameData and mmGameData.RequestedGamemode then
        requestedGamemode = mmGameData.RequestedGamemode
    end

    -- we start!
    GameService:Main(requestedGamemode)
end

-- Starts the specified or default gamemode.
function GameService:Main(gamemodeStr: string?)

    -- get gamemode class
    local gamemode = getGMod(gamemodeStr)
    if not gamemode then
        gamemode = getGMod(DEFAULT_GAMEMODE)
    end
    gamemode = require(gamemode)

    -- set CurrentGamemode, GameOptions, Menu Type
    self.CurrentGamemode = gamemode
    self.CurrentGamemode.Name = gamemodeStr
    self.GameOptions = table.clone(gamemode.GameOptions)
    GamemodeService2:SetMenuType(self.GameOptions.MENU_TYPE)
    GamemodeService2.CurrentGamemode = gamemodeStr

    -- init game
    self:InitalizeGame()

    -- start game!
    gmCall("Start")

    -- start round
    self:RoundStart()
end

function GameService:InitalizeGame()

    RequestSpawnEvent.OnServerInvoke = function()
        return false
    end

    GamemodeService2:SetMenuType(self.GameOptions.MENU_TYPE)

    local Spawns = ServerStorage:FindFirstChild("Spawns")
    if Spawns then Spawns:Destroy() end
    Spawns = getGMod(self.CurrentGamemode.Name).Spawns:Clone()
    Spawns.Parent = ServerStorage
    Spawns.Name = "Spawns"
    self.Spawns = Spawns

    -- init var
    self.GameStatus = "LOADING" :: Types.GameServiceStatus
    self.RoundStatus = "LOADING" :: Types.GameServiceStatus
    self.StartTime = tick()
    self.TimeElapsed = 0
    self.CurrentRound = 0

    -- init player and team data
    self.PlayerData = nil
    self.TeamData = nil
    self.PlayerData = GM_PlayerData.new()
    self.PlayerData.DefaultData.spectator = false
    self.PlayerData.DefaultData.inventory = table.clone(self.GameOptions.START_INVENTORY)
    self.PlayerData.DefaultData.alive = false
    if self.GameOptions.TEAMS_ENABLED then
        self.PlayerData.DefaultData.team = ""
        self.TeamData = GM_PlayerData.new()
        self.TeamData.DefaultData.players = {}
        self.Teams = {attackers = {Name = "attackers"}, defenders = {Name = "defenders"}} -- fake Player instances for team.
        self.TeamData:AddPlayer(self.Teams.attackers)
        self.TeamData:AddPlayer(self.Teams.defenders)
    end

    -- force spawn request?
    if self.GameOptions.REQUIRE_REQUEST_SPAWN then
        self.PlayerData.DefaultData.initialSpawned = false
    end

    -- init players
    for _, v in pairs(Players:GetPlayers()) do
        self:InitPlayer(v)
    end

    --@Event PLAYER ADDED MAIN CONNECTION
    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)

        self:InitPlayer(player)

        -- game is full
        if #Players:GetPlayers() >= self.GameOptions.MAX_PLAYERS then

            if self.GameOptions.SPECTATE_ENABLED then
                -- move to spectate
                self.PlayerData:Set(player, "spectator", true)
            else
                --TODO: Put them in a non-full lobby?
                player:Kick("Game full, please find a new game.")
            end

            return
        end

        -- round is started
        if self.RoundStatus == "STARTED" then
            
            -- call SpawnPlayer function from here. this will be the only time GameService uses the SpawnPlayer function.
            if self.GameOptions.PLAYER_SPAWN_ON_JOIN then
                gmCall("SpawnPlayer", player)
            else
                -- PlayerJoinedDuringRound is handled by the Class unless SPECTATE_ENABLED
                gmCall("PlayerJoinedDuringRound", player)
            end
        end
    end)

    -- BUY MENU
    if self.GameOptions.BUY_MENU_ENABLED then
        self.Connections.BuyMenu = GameServiceRemotes.BuyMenuEvent.OnServerEvent:Connect(function(_bmplayer, action, item, slot)
            if action == "AbilitySelected" then
                local inv = self.PlayerData:Get(_bmplayer, "inventory")
                inv.ABILITIES[slot] = item
                self.PlayerData:Set(_bmplayer, "inventoy", inv)
                if self.GameOptions.BUY_MENU_ADD_INSTANT then
                    AbilityService:AddAbility(_bmplayer, item)
                end
            elseif action == "WeaponSelected" then
                local inv = self.PlayerData:Get(_bmplayer, "inventory")
                inv.WEAPONS[slot] = item
                self.PlayerData:Set(_bmplayer, "inventoy", inv)
                if self.GameOptions.BUY_MENU_ADD_INSTANT then
                    WeaponService:AddWeapon(_bmplayer, item)
                end
            end
        end)
    end

    -- WAITING FOR PLAYERS
    if #self.PlayerData:GetPlayers() < self.GameOptions.MIN_PLAYERS then
        repeat task.wait(0.5) until #self.PlayerData:GetPlayers() >= self.GameOptions.MIN_PLAYERS
    end

    -- INITIALIZE TEAMS
    if self.GameOptions.TEAMS_ENABLED then
        local plrs = Table.clone(self.PlayerData:GetPlayers())
        plrs = Table.shuffle(plrs)

        for i, v in pairs(plrs) do
            local team = i % 2 == 0 and "attackers" or "defenders"
            self.PlayerData:Set(v, "team", team)
            self.TeamData:Insert(self.Teams[team], "players", v)
        end
    end

    --@Event PLAYER DIED MAIN CONNECTION
    self.Connections.PlayerDied = PlayerDiedEvent.OnServerEvent:Connect(function(died, killer)
        self:PlayerDied(died, killer)
    end)

    -- REQUEST SPAWN
    if self.GameOptions.REQUIRE_REQUEST_SPAWN then
        RequestSpawnEvent.OnServerInvoke = function(plr)
            local pd = self.PlayerData:GetPlayer(plr)

            if not pd then
                warn("Player does not have playerdata, cant spawn.")
                return false
            end
            if pd.initialSpawned then
                warn("Player already spawned, cant spawn.")
                return false
            end

            self.PlayerData:Set(plr, "initialSpawned", true)
            gmCall("SpawnPlayer", plr)
            return true
        end
    end

    self:RoundStart()
end

function GameService:InitPlayer(player)
    if not self.PlayerData:GetPlayer(player) then
        self.PlayerData:AddPlayer(player)
        GameServiceRemotes.SetUIGamemode:FireClient(player, self.CurrentGamemode.Name)
        gmCall("InitPlayer", player)
    end
end

function GameService:EndGame(result, ...)
    gmCall("End", result, ...)

    -- clear connections and restart
    for _, v in pairs(self.Connections) do
        v:Disconnect()
    end
end

function GameService:RoundStart()
    self.RoundStatus = "STARTED"

    self.TimeElapsed = 0
    self.Connections.Timer = RunService.Heartbeat:Connect(function(dt)
        self:TimerUpdate(dt)
    end)

    gmCall("RoundStart")
end

function GameService:RoundEnd(startNewRound: boolean, result: string, ...: any)
    self.RoundStatus = "ENDED"
    self.Connections.Timer:Disconnect()

    gmCall("RoundEnd", "Condition", ...)

    if startNewRound then
        task.delay(self.GameOptions.ROUND_WAIT_TIME, function()
            self:RoundStart()
        end)
    end
end

function GameService:TimerUpdate(dt)
    self.TimeElapsed += dt
    if self.TimeElapsed >= GameService.GameOptions.ROUND_LENGTH and self.GameStatus ~= "ENDED" then
        self.GameStatus = "ENDED"
        self:TimerEnded()
    end
end

function GameService:TimerEnded()

    if self.GameOptions.ROUND_END_CONDITION == "Custom"
    or self.GameOptions.GAME_END_CONDITION == "Custom" then
        gmCall("TimerEnded")
        return
    end

    if self.GameOptions.GAME_END_CONDITION == "TimerScore"
    or self.GameOptions.GAME_END_CONDITION == "Score" then

        -- get player with highest score (kills)
        local winner = false
        local highest = 0
        for _, v in pairs(self.PlayerData:GetPlayers()) do
            if self.PlayerData:Get(v, "kills") > highest then
                winner = v
                highest = self.PlayerData:Get(v, "kills")
            end
        end

        self:EndGame("Condition", winner)
    end
end

function GameService:PlayerDied(died, killer)
    local killRegistered = false

    self.PlayerData:Set(died, "alive", false)

    WeaponService:ClearPlayerInventory(died)
    AbilityService:ClearPlayerInventory(died)

    -- increment deaths
    self.PlayerData:Increment(died, "deaths", 1)

    -- only increment kills if player did not kill self
    if killer and died ~= killer then
        killRegistered = true
        self.PlayerData:Increment(killer, "kills", 1)
    end

    if not killRegistered then
        -- fire with killNotRegistered
        gmCall("PlayerDied", died, killer, true)
    else
        -- fire normally!
        gmCall("PlayerDied", died, killer)
    end

    -- round will end if (PlayerKilled)
    if self.GameOptions.ROUND_END_CONDITION == "PlayerKilled" then

        -- will game end?
        -- check if round score is won
        if self.GameOptions.GAME_END_CONDITION == "RoundScore"
        and getRoundScore(killer) >= self.GameOptions.SCORE_TO_WIN then
            self:EndGame("Condition", killer)
            return
        end

        self:RoundEnd(true, "Condition", killer)
        return
    end

    -- No round or game end handling for custom gamemode.
    if self.GameOptions.ROUND_END_CONDITION == "Custom"
    or self.GameOptions.GAME_END_CONDITION == "Custom" then
        return
    end

    -- Team Killed
    if self.GameOptions.ROUND_END_CONDITION == "TeamKilled" then
        return
    end

    if self.GameOptions.RESPAWN_ENABLED then
        task.delay(self.GameOptions.RESPAWN_LENGTH, function()
            gmCall("SpawnPlayer", died)
        end)
    end
end

return GameService
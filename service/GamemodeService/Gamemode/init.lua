--[[

    The Main Gamemode Class
    The base configuration will give you a 1v1 gamemode.

    To create a new Gamemode, create a new Class as a child to this one, with the name set as the Gamemode Name.
    Create a Table within the class called "GameVariables" and set any custom variables you would like.
    Add any functionality by overriding a base function.

    ex: Check Deathmatch script.

    [Tags]
    "GamemodeDestroyOnStop"
    "GamemodeDestroyOnRoundOver"
    "GamemodeDestroyOnDeath_{PlayerName}"

]]

-- [[ CONFIGURATION ]]
local LobbyID = 11287185880

local GamemodeClasses = {}
for i, v in pairs(script:GetChildren()) do
    if v:IsA("ModuleScript") then
        table.insert(GamemodeClasses, v)
    end
end

function GamemodeClasses.Find(gamemode: string) for _, v in pairs(GamemodeClasses) do 
    if v.Name == gamemode then
        return v end
    end
    return false
end

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Types = require(script.Parent:WaitForChild("Types"))
local EnableMainMenuRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("EnableMainMenu")
local Teams = game:GetService("Teams")
local TeleportService = game:GetService("TeleportService")
local RoundTimer = require(script.Parent:WaitForChild("RoundTimer"))
local Framework = require(game.ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(game.ReplicatedStorage.Services.WeaponService)
local AbilityService = require(game.ReplicatedStorage.Services.AbilityService)
local EvoPlayer = require(game.ReplicatedStorage.Modules.EvoPlayer)
local EvoMM = require(game.ReplicatedStorage.Modules.EvoMMWrapper)
local Tables = require(Framework.Module.lib.fc_tables)
local BotService = require(game.ReplicatedStorage:WaitForChild("Services"):WaitForChild("BotService"))
local BuyMenuService = require(Framework.Service.BuyMenuService)
local BuyMenuTypes = BuyMenuService.Types

local DefaultScripts = script:WaitForChild("Scripts")
local DefaultSpawns = script:WaitForChild("Spawns")
local DefaultGuis = script:WaitForChild("Guis")
local DefaultBots = script:WaitForChild("Bots")
local DefaultLeaderboard = script:WaitForChild("Leaderboard")
local BindableEvent = script.Parent:WaitForChild("BindableEvent")

local Gamemode = {} :: Types.Gamemode
Gamemode.__index = Gamemode

Gamemode.GameVariables = {

    -- [[ GENERAL ]]
    game_type = "Round" :: Types.GameType,
    minimum_players = 2,
    maximum_players = 2,
    bots_enabled = false,
    leaderboard_enabled = true,
    spawn_objects = DefaultSpawns,

    -- [[ QUEUING ]]
    queueFrom_enabled = false, -- Can a player queue while in this gamemode?
    queueTo_enabled = true,    -- Can a player queue into this gamemode while in a queueFrom enabled gamemode?

    -- [[ MAIN MENU ]]
    main_menu_type = "Default", -- the string that the main menu requests upon init, and that is sent out upon gamemode changed

    -- [[ TEAMS ]]
    teams_enabled = false,
    players_per_team = 1,

    -- [[ PLAYER SPAWNING ]]
    opt_to_spawn = false,           -- should players spawn in automatically, or opt in on their own? (lobby)
    characterAutoLoads = false,     -- roblox CharacterAutoLoads
    respawns_enabled = false,
    respawn_length = 3,
    spawn_invincibility = 3,        -- set to false for none
    starting_health = 100,
    starting_shield = 50,
    starting_helmet = true,

    -- [[ PLAYER DEATH ]]
    death_camera_enabled = true,
    death_camera_custom_script = false,

    -- [[ ROUNDS ]]     : game_type == Round
    round_length = 60,
    round_end_timer_callback = "RoundScore" :: Types.RoundOverTimerCallbackType,
    round_end_condition = "PlayerEliminated" :: Types.RoundEndCondition,
        -- if round_end_condition == ScoreReached
        round_score_to_win_round = 1,
        round_score_increment_condition = "Kills" :: Types.RoundScoreIncrementCondition,

    -- [[ OVERTIME ]]   : game_type == Round
    overtime_enabled = true,
    overtime_round_score_to_win_game = 1,
    overtime_round_score_to_win_round = 1,

    -- [[ GAME END CONDITIONS ]]
    game_score_to_win_game = 7,             -- if game_type == "Score"
    game_rounds_to_win_game = 7,            -- if game_type == "Round
    kick_players_on_end = true,             -- Kick players or Restart game?

    -- [[ BUY MENU, WEAPONS, ABILITIES & DAMAGING ]]
    can_players_damage = true,
    start_with_knife = true,
    auto_equip_strongest_weapon = true,

    weapon_pool = {
        light_primary = {"vityaz"},
        primary = {"ak103", "acr"},

        light_secondary = {"glock17"},
        secondary = {"deagle"}
    },

    ability_pool = {
        movement = {"Dash"},
        utility = {"LongFlash", "Molly", "SmokeGrenade"}
    },

    starting_weapons = false,
    starting_abilities = false,

    buy_menu_enabled = false, -- if buy menu is enabled, buy_menu_starting_loadout must also be set.
    buy_menu_add_bought_instant = false, -- should the weapon/ability be added instantly or when they respawn
    buy_menu_starting_loadout = {
        Weapons = {primary = "ak103", secondary = "glock17"},
        Abilities = {primary = "Dash", secondary = "LongFlash"}
    },
    buy_menu_open_on_spawn = false,

    --[[starting_weapons = {
        secondary = "glock17", primary = "ak47"
    },]]
    --[[starting_abilities = {
        "Dash"
    },]]
}

--@summary Create a new GamemodeClass.
function Gamemode.new(gamemode: string, customGameVar: table?)
    local gamemodeModule = {Name = "1v1"}
    local gamemodeClass = {}
    if gamemode ~= "1v1" then -- 1v1 is the base gamemode.
        gamemodeModule = GamemodeClasses.Find(gamemode)
        if not gamemodeModule then
            warn("GamemodeClass: GamemodeClass " .. tostring(gamemode) .. " not found.")
            return false
        end

        -- We have to clone the module here or else we are just overriding the values in the module script.
        gamemodeClass = Tables.clone(require(gamemodeModule))
    end

    -- inherit missing GameVariables
    for i, v in pairs(Gamemode.GameVariables) do
        if not gamemodeClass.GameVariables then break end
        if gamemodeClass.GameVariables[i] == nil then
            gamemodeClass.GameVariables[i] = v
        end
    end

    if customGameVar then
        for i, v in pairs(customGameVar) do
            gamemodeClass.GameVariables[i] = v
        end
    end

    local GamemodeClone = Tables.clone(Gamemode)
    GamemodeClone.GameVariables = nil
    gamemodeClass = setmetatable(gamemodeClass, GamemodeClone)
    gamemodeClass.Name = gamemodeModule.Name
    gamemodeClass.Status = "Init"

    gamemodeClass.PlayerData = {}
    gamemodeClass.GameData = {Connections = {}, Round = {Current = 1, Status = "Ended"}}

    Players.CharacterAutoLoads = gamemodeClass.characterAutoLoads
    return gamemodeClass :: Types.Gamemode
end

--

--@summary Start the Gamemode.
function Gamemode:Start(isInitialGamemode: boolean?)
    if self.Status == "Paused" then
        self:StartRound()
        return
    end

    self.Status = "Running"

    if self.GameVariables.queueFrom_enabled then
        EvoMM:StartQueueService({"1v1"})
    end

    if self.GameVariables.buy_menu_enabled then
        BuyMenuService:Start(false, {equipBoughtInstant = self.GameVariables.buy_menu_add_bought_instant, openOnSpawn = self.GameVariables.buy_menu_open_on_spawn})
    end

    -- initial PlayerAdded connection (fill up to minimum players)
    local initWhenLoadingPlayers = {}
    self.GameData.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        table.insert(initWhenLoadingPlayers, player.Name)
        EvoPlayer:DoWhenLoaded(player, function()
            self:PlayerInit(player)
        end)
    end)

    -- init current players incase they weren't added recently
    for _, player in pairs(Players:GetPlayers()) do
        if not table.find(initWhenLoadingPlayers, player.Name) then
            table.insert(initWhenLoadingPlayers, player.Name)
            EvoPlayer:DoWhenLoaded(player, function()
                self:PlayerInit(player)
            end)
        end
    end

    -- i cant think of a reason not to pause the script here while we wait
    if self:PlayerGetCount() < self.GameVariables.minimum_players then
        repeat task.wait(0.5) print(self:PlayerGetCount()) until self:PlayerGetCount() >= self.GameVariables.minimum_players or self.Status ~= "Running"
        if self.Status ~= "Running" then
            return
        end
    end

    -- divide players into teams
    if self.GameVariables.teams_enabled then
        local teams = self.GameVariables.players_per_team/self:PlayerGetCount()
        local teamnames = {"Red", "Blue", "Green", "Purple"}
        local playercounter = 0
        for i = 1, teams do
            local _team = Instance.new("Team", Teams)
            _team.Name = teamnames[i]
            for _ = 1, self.GameVariables.players_per_team do
                playercounter += 1
                local playerdata = self:PlayerGetDataByNumberIndex(playercounter)
                if playerdata then
                    playerdata.Player.Team = _team
                end
            end
        end
    end
    
    self.GameData.Connections.PlayerAdded:Disconnect()

    if isInitialGamemode then -- we dont need to add blackscreen if there was a gamemode before this, since gamemode:Stop() does it already.
        self:GuiBlackScreenAll(false, 0.1, 0.5, true)
    end

    task.wait()
    
    self:RemoveTagged("WaitingForPlayersHUD")
    self:GuiInit("all")

    if self.GameVariables.bots_enabled then
        local botprop = {SpawnCFrame = true}
        if self.GameVariables.starting_shield then
            botprop.StartingShield = self.GameVariables.starting_shield
        end
        if self.GameVariables.starting_helmet then
            botprop.StartingHelmet = true
        end
        for _, v in pairs(DefaultBots:GetChildren()) do
            botprop.SpawnCFrame = v.PrimaryPart.CFrame
            BotService:AddBot(botprop)
        end
    end

    self.GameData.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        self:PlayerJoinedDuringRound(player)
    end)

    if self.GameData.Connections.PlayerDied then
        self.GameData.Connections.PlayerDied:Disconnect()
        self.GameData.Connections.PlayerDied = nil
        task.wait(0.25)
    end

    if self.GameVariables.game_type == "Round" then
        self.GameData.Round.Status = "Init"
        self.GameData.cancel_death_listener = true
        for _, v in pairs(self.PlayerData) do
            pcall(function()
                if v.Player.Character and v.Player.Character.Humanoid then
                    v.Player.Character.Humanoid:TakeDamage(1000)
                end
            end)
        end
    end

    task.wait(0.25)

    self:StartRound()
end

--@summary Pause the Gamemode.
function Gamemode:Pause()
end

--@summary End the Gamemode.
function Gamemode:Stop()
    if self.GameData.RoundTimer and self.GameData.RoundTimer.Status ~= "Stopped" then
        self.GameData.RoundTimer:Stop("Restart")
    end

    if self.GameData.Connections.PlayerDied then
        self.GameData.Connections.PlayerDied:Disconnect()
    end

    for _, v in pairs(self.GameData.Connections) do
        v:Disconnect()
    end

    self:GuiBlackScreenAll(false, 0.5, 0.3, true)
    WeaponService:ClearAllPlayerInventories()
    self:PlayerRemoveAll()
    self:RemoveTagged("GamemodeDestroyOnStop")

    workspace.Temp:ClearAllChildren()

    if self.GameVariables.queueFrom_enabled then
        task.spawn(function()
            EvoMM:StopQueueService()
        end)
    end

    if self.GameVariables.buy_menu_enabled then
        BuyMenuService:Stop()
    end

    if self.GameVariables.bots_enabled then
        BotService:RemoveAllBots()
    end

    -- probably keep track of any Gamemode related workspace objects under a tag and clear those here
    return true
end

--@summary Start the overtime phase of the game.
function Gamemode:InitOvertime()
end

--

--@summary Starts a round of the game.
-- This function will still run even if rounds_enabled = false, in that case the CurrentRound would just stay 1.
-- Called in :Start() and at some point during :EndRound()
function Gamemode:StartRound()

    if self.GameVariables.game_type == "Round" then
        if self.GameData.Round.Status == "Started" or self.GameData.Round.Status == "PreInit" or self.GameData.Round.Status == "Running" then
            warn("Round is already running!")
            return false
        end
    
        self.GameData.Round.Status = "PreInit"
    
        if self.GameVariables.round_end_condition == "scoreReached" then
            for i, _ in pairs(self.PlayerData) do
                self.PlayerData[i].Round = {Score = 0}
            end
        end
    end

    local _1v1content = nil
    if self.Name == "1v1" then
        _1v1content = self:GetRoundPlayerContent()
    end

    task.delay(1, function()
        if not self.GameVariables.opt_to_spawn then
            self:GuiRemoveBlackScreen("all", false)
            self:PlayerSpawnAll(_1v1content)
        else
            self:GuiMainMenu("all", true)
            self:GuiRemoveBlackScreen("all", false)
        end
        
        -- StartRoundTimer and EndRound via Timer
        if self.GameVariables.game_type == "Round" or self.GameVariables.game_type == "Timer" then
            self.GameData.Round.Status = "Running"
            -- start round timer
            local RoundFinished = self:StartRoundTimer()
            RoundFinished.Event:Once(function(result)
                if result ~= "Restart" then
                    self:EndRound("RoundOverTimer")
                    RoundFinished:Destroy()
                end
            end)
        end
    end)

    self.GameData.Connections.PlayerDied = EvoPlayer.PlayerDied:Connect(function(killed, killer)
        if self.GameVariables.game_type == "Round" then
            if self.GameData.Round.Status ~= "Running" then
                return
            end
            self.GameData.Round.Status = "Verify"
            self:_PlayerDiedCore(killed, killer)
            return
        end
        self:_PlayerDiedCore(killed, killer)
    end)
end

--@summary Ends a round of the game. Called automatically when the RoundTimer is done, or when the win condition is met. 
-- Called in :StartRound()
function Gamemode:EndRound(result, winner, loser)
    task.delay(3, function()
        for i, v in pairs(workspace:WaitForChild("Temp"):GetChildren()) do
            v:Destroy()
        end
    end)

    if self.GameData.Connections.PlayerDied then
        self.GameData.Connections.PlayerDied:Disconnect()
    end

    self:RemoveTagged("GamemodeDestroyOnRoundOver")
    WeaponService:ClearAllPlayerInventories()
    self:GuiUpdateGamemodeBarAll("StopTimer")

    if self.GameVariables.game_type == "Round" then
        task.wait(3)

        for _, v in pairs(self.PlayerData) do
            pcall(function()
                if v.Player.Character and v.Player.Character.Humanoid then
                    v.Player.Character.Humanoid:TakeDamage(1000)
                end
            end)
        end

        self:GuiBlackScreenAll(false, 0.5, 0.5, true)

        self.GameData.Round.Status = "Ended"
        self.GameData.Round.Current += 1
        if result == "RoundOverWon" then
            return self:_RoundOverWonCore(winner, loser)
        elseif result == "RoundOverTimer" then
            return self:RoundOverTimer()
        end
    end

    self:_GameOverCore(winner)
end

--@summary Start the timer of a rounds_enabled Gamemode.
function Gamemode:StartRoundTimer(): BindableEvent
    if self.GameData.RoundTimer and self.GameData.RoundTimer.Status == "Started" then
        warn("RoundTimer already started!")
        return false
    end

    if self.GameData.Connections.RoundTimerTimeUpdated then
        self.GameData.Connections.RoundTimerTimeUpdated:Disconnect()
    end

    self:GuiUpdateGamemodeBarAll("StartTimer", self.GameVariables.round_length)

    self.GameData.RoundTimer = RoundTimer.new(self.GameVariables.round_length)
    self.GameData.Connections.RoundTimerTimeUpdated = self.GameData.RoundTimer.TimeUpdated.Event:Connect(function(newTime)
        -- update player's HUD
    end)
    self.GameData.RoundTimer:Start()
    return self.GameData.RoundTimer.Finished
end

--@summary Called in :_RoundOverWonCore() when rounds_enabled = true and the round is won via playerElim or teamElim
-- Called after it is known that the game has not been finished.
function Gamemode:RoundOverWon(winner, loser)
    -- add a nice gui to all players, then wait 3 seconds before starting the next round.
    self:GuiRoundOver("all", winner, loser)
    task.wait(3)
end

--@final
--@summary For game win conditioning. Called by default when a round is won by condition. Not recommended to override.
function Gamemode._RoundOverWonCore(self, winner, loser)

    self.GameData.RoundTimer:Stop()

    if self.GameVariables.teams_enabled then
        local winningTeam = winner.Team
        -- team won stuff
        return
    end

    self.PlayerData[winner.Name].Score += 1

    if self.GameVariables.game_end_condition == "scoreReached" then
        if self.PlayerData[winner.Name].Score >= self.GameVariables.game_score_to_win_game then
            self:_GameOverCore(winner, loser)
            return
        end

        local otscore = self.GameVariables.game_score_to_win_game - 1
        if self.PlayerData[winner.Name].Score == otscore and self.PlayerData[loser.Name] == otscore then
            self.GameData.IsOvertime = true
            self:InitOvertime()
        end
    end
    
    self:RoundOverWon(winner, loser)

    self:StartRound()
end

--@summary Score Sort Utility -- Returns Array of PlayerNames
function Gamemode:SortPlayersByScore()
    local scores = {}
    for name, data in pairs(self.PlayerData) do
        if table.find(scores, name) then continue end
        scores = self:ScoreSortPlayer(name, data, scores)
    end
    return scores
end

function Gamemode:ScoreSortPlayer(name, data, scores)
    if #scores == 0 then
        scores[1] = name
        return scores
    end
    for sindex, sname in scores do
        if data.Score > self.PlayerData[sname].Score then
            scores[sindex+1] = sname
            scores[sindex] = name
            break
        end
    end
    return scores
end
--

--@summary Called in :EndRound() when GameType == "Round" and the timer runs out.
function Gamemode:RoundOverTimer()
    local roundEndAssign = self.GameVariables.round_end_timer_callback
    if roundEndAssign then

        local winner
        local loser = false

        if roundEndAssign == "roundScore" or roundEndAssign == "health" then
            local function getAssignment(player)
                return
                roundEndAssign == "roundScore" and self.PlayerData[player.Name].Round.Score
                or (player.Character and player.Character.Humanoid.Health or 0)
            end

            local highest
            for _, plrdata in pairs(self.PlayerData) do
                local ass = getAssignment(plrdata.Player) -- ass is roundScore or health
                if not highest or ass > highest[2] then
                    highest = {plrdata.Player, ass}
                end
            end
            if not highest then error("Couldnt find highest ranking round player") end
            winner = highest[1]
        elseif roundEndAssign == "random" then
            local r = math.random(1,#self:PlayerGetCount())
            winner = self:PlayerGetDataByNumberIndex(r)
        end

        if not winner then
            error("Could not get winner from round!")
        end

        -- assign "loser" player if necessary
        loser = self.Name == "1v1" and self:PlayerGetOtherPlayer(winner) or false
        return self:_RoundOverWonCore(winner, loser) -- No need to call EndRound here since it was already called
    end
end

--@summary Called at the end of :EndRound if GameType ~= "Round"
function Gamemode:_GameOverCore(winner: Player?)
    print('games over!')
    for i, v in pairs(Players:GetPlayers()) do
        print(v)
        if v.Character then v.Character.Humanoid:TakeDamage(10000)v.Character = nil end
    end
    self:GameOver(winner)

    if self.GameVariables.kick_players_on_end then
        TeleportService:TeleportAsync(LobbyID, Players:GetPlayers())
        return
    end

    -- this event will handle stopping and restarting in GamemodeService.
    self.RestartGamemodeFromService:Fire()
end

--@summary Called at the beginning of _GameOverCore
function Gamemode:GameOver(winner: Player?)
    self:GuiGameOver("all", winner)
    task.wait(5)
end

--@summary Remove all tagged objects from the workspace.
function Gamemode:RemoveTagged(tag: string)
    for _, ui in pairs(CollectionService:GetTagged(tag)) do
        ui:Destroy()
    end
end

--

--@summary Initialize a player into the gamemode. Called usually in the PlayerAdded connection.
function Gamemode:PlayerInit(player)
    if self.PlayerData[player.Name] then
        warn("GamemodeClass: Can't init player. " .. player.Name .. " is already initialized!")
        return
    end

    EvoPlayer:DoWhenLoaded(player, function()
        if self:PlayerGetCount() < self.GameVariables.minimum_players then
            --self:GuiWaitingForPlayers(player, "WaitingForPlayersHUD")
        end
    end)
    
    self.PlayerData[player.Name] = {
        Player = player,
        Kills = 0,
        Deaths = 0
    }

    if self.GameVariables.game_type == "Round" then
        self.PlayerData[player.Name].Score = 0
        if self.GameVariables.round_end_condition == "ScoreReached" then
            self.PlayerData[player.Name].Round = {Score = 0}
        end
    elseif self.GameVariables.game_type == "Score" then
        self.PlayerData[player.Name].Score = 0
    end

    if self.GameVariables.buy_menu_enabled then
        local loadout = self.GameVariables.buy_menu_starting_loadout
        BuyMenuService:SetInventory(player, {
            Weapon = {
                primary = loadout.Weapons.primary,
                secondary = loadout.Weapons.secondary,
                ternary = "knife"
            },
            Ability = {
                primary = loadout.Abilities.primary,
                secondary = loadout.Abilities.secondary
            }
        }:: BuyMenuTypes.BuyMenuPlayerInventory)
    end

end

--@summary Spawn a player. Called either in PlayerSpawnAll() or during respawn on PlayerDied()
function Gamemode:PlayerSpawn(player, content, index)
    if self.GameVariables.death_camera_enabled then
        self:PlayerRemoveDeathCamera(player)
    end

    task.wait()

    player:LoadCharacter()

    if self.Name == "1v1" then
        player.Character:SetPrimaryPartCFrame(content and content.spawns[index].CFrame)
    else
        player.Character:SetPrimaryPartCFrame(self:PlayerGetSpawnPoint(player))
    end

    player.Character:WaitForChild("Humanoid").Health = self.GameVariables.starting_health
    local shield, helmet = self.GameVariables.starting_shield, self.GameVariables.starting_helmet

    if self.GameVariables.spawn_invincibility then
        EvoPlayer:SetSpawnInvincibility(player.Character, true, self.GameVariables.spawn_invincibility)
    end

    -- equip strongest weapon
    local strongestWeapon = "ternary"
    local bml = BuyMenuService:GetInventory(player) :: BuyMenuTypes.BuyMenuPlayerInventory

    if self.GameVariables.auto_equip_strongest_weapon then
        if bml then
            strongestWeapon = bml.Weapon.primary and "primary" or "secondary"
        else
            if self.GameVariables.starting_weapons then
                strongestWeapon = self.GameVariables.starting_weapons.primary and "primary" or "secondary"
            end
        end
    end

    if self.GameVariables.start_with_knife then
        WeaponService:AddWeapon(player, "Knife", strongestWeapon == "ternary")
    end

    if bml then
        for i, v in pairs(bml.Weapon) do
            if not v then continue end
            WeaponService:AddWeapon(player, v, strongestWeapon == i)
        end
        for _, v in pairs(bml.Ability) do
            if not v then continue end
            AbilityService:AddAbility(player, v)
        end
    else
        if self.GameVariables.starting_weapons then
            for i, v in pairs(self.GameVariables.starting_weapons) do
                WeaponService:AddWeapon(player, v, strongestWeapon == i)
            end
        end
        if self.GameVariables.starting_abilities then
            for _, v in pairs(self.GameVariables.starting_abilities) do
                AbilityService:AddAbility(player, v)
            end
        end
    end

    if self.GameVariables.leaderboard_enabled and not player:WaitForChild("PlayerGui"):FindFirstChild("Leaderboard") then
        self:GuiAddLeaderboard(player)
    end

    if self.Name == "1v1" then
        for _, v in pairs(content.weapons) do
            WeaponService:AddWeapon(player, v)
        end
        task.delay(0.9, function()
            for _, v in pairs(content.abilities) do
                AbilityService:AddAbility(player, v)
            end
        end)
        shield, helmet = content.shield.shield, content.shield.helmet
    end

    EvoPlayer:SetShield(player.Character, shield)
    EvoPlayer:SetHelmet(player.Character, helmet)
end

function Gamemode:PlayerGetSpawnPoint(player)
    return DefaultSpawns.Default.CFrame
end

--@summary Remove a player from the gamemode. Called on PlayerRemoving
function Gamemode:PlayerRemove(player)

    if player and player.Character then
        pcall(function() player.Character.Humanoid:TakeDamage(1000) end)
        task.delay(0.01, function()
            player.Character = nil
        end)
    end

    if self.GameData.PlayerData then
        if self.GameData.PlayerData[player.Name] then
            self.GameData.PlayerData[player.Name] = nil
        end
    end
    return true
end

--@summary Spawn all of the players in self.PlayerData. Called when all players are to be spawned.
function Gamemode:PlayerSpawnAll(content)
    if content and self.Name == "1v1" then
        local counter = 0 -- for tables indexing
        for _, v in pairs(self.PlayerData) do
            counter += 1
            self:PlayerSpawn(v.Player, content, counter)
        end
        return
    else
        for _, v in pairs(self.PlayerData) do
            if not v.Player.Character then
                EvoPlayer:DoWhenLoaded(v.Player, function()
                    self:PlayerSpawn(v.Player)
                end)
            end
        end
    end
end

--@summary Remove all players from the gamemode.
function Gamemode:PlayerRemoveAll()
    for _, v in pairs(self.PlayerData) do
        self:PlayerRemove(v.Player)
    end
    self.PlayerData = {}
end

--@summary Called when a player dies.
--         Ran in PlayerDiedCore at the very end
function Gamemode:PlayerDied(player, killer)
end

--@summary Called in PlayerDiedCore if death_camera_enabled
function Gamemode:PlayerAddDeathCamera(player, killer)
    if not killer then killer = player end
    local dscript = (self.GameVariables.death_camera_custom_script and self.GameVariables.death_camera_custom_script or DefaultScripts.DeathCamera):Clone()
    dscript.Parent = player.Character
    local ko = Instance.new("ObjectValue", dscript)
    ko.Name = "killerObject"
    ko.Value = killer
    self.PlayerData[player.Name].DeathCameraScript = dscript
end

--@summary Called in PlayerSpawn if death_camera_enabled
function Gamemode:PlayerRemoveDeathCamera(player)
    if self.PlayerData[player.Name].DeathCameraScript then
        self.PlayerData[player.Name].DeathCameraScript:WaitForChild("Finished"):FireClient(player)
        task.delay(1, function()
            self.PlayerData[player.Name].DeathCameraScript:Destroy()
            self.PlayerData[player.Name].DeathCameraScript = nil
        end)
    end
end

--@final
--@summary For win conditioning, respawns, etc. Called by default when a Player dies. Not recommended to override.
function Gamemode._PlayerDiedCore(self, player, killer)
    if self.GameVariables.death_camera_enabled then
        self:PlayerAddDeathCamera(player, killer)
    end

    if self.GameVariables.respawns_enabled then
        task.delay(self.GameVariables.respawn_length, function()
            self:PlayerSpawn(player)
        end)
    end

    local tagged = CollectionService:GetTagged(player.Name .. "ClearOnDeath")
    if tagged then
        for _, v in pairs(tagged) do
            v:Destroy()
        end
    end

    if killer then
        self.PlayerData[killer.Name].Kills += 1
    end
    self.PlayerData[player.Name].Deaths += 1

    if self.GameVariables.leaderboard_enabled then
        self:GuiUpdateLeaderboardAll()
    end

    Gamemode.PlayerDiedGameType[self.GameVariables.game_type](self, player, killer)

    self:PlayerDied(player, killer)
end

--@summary Called when a PlayerDied and game_type == "Round"
function Gamemode:PlayerDiedRound(player, killer)
    if not killer then
        self.GameData.Round.Status = "Running"
        return true
    end

    if killer == player or not killer then
        if self.PlayerDiedIsKiller then
            return self:PlayerDiedIsKiller(player)
        end
    elseif self.GameVariables.round_end_condition == "ScoreReached" and self.GameVariables.round_score_increment_condition == "Kills" then
        if not self.PlayerData[killer.Name].Round.Score then
            self.PlayerData[killer.Name].Round.Score = 0
        end
        self.PlayerData[killer.Name].Round.Score += 1
    end
    if self.GameVariables.round_end_condition == "PlayerEliminated" then
        return self:EndRound("RoundOverWon", killer, player)
    end
    if self.GameVariables.round_end_condition == "TeamEliminated" then
        -- check alive status of team members
        local aliveTeamMembers = 0
        if aliveTeamMembers <= 0 then
            return self:EndRound("RoundOverWonTeam", killer, player)
        end
    end
    if self.GameVariables.round_end_condition == "ScoreReached" then
        if not killer then
            self.GameData.Round.Status = "Running"
            return end
        if self.PlayerData[killer.Name].Round.Score == self.GameVariables.round_score_to_win_round then
            return self:EndRound("RoundOverWon", killer, player)
        end
    end

    self.GameData.Round.Status = "Running"
    return true
end

--@summary Called when a PlayerDied and game_type == "Score"
function Gamemode:PlayerDiedScore(player, killer)
    if not killer or player == killer or player.Name == killer.Name then
        return
    end
    self.PlayerData[killer.Name].Score += 1
    if self.PlayerData[killer.Name].Score >= self.GameVariables.game_score_to_win_game then
        self:GameOver(killer)
    end
end

--@summary Called when a PlayerDied and game_type == "Timer"
function Gamemode:PlayerDiedTimer(player, killer)
end

--@summary Called when a PlayerDied and game_type == "Custom"
function Gamemode:PlayerDiedCustom(player, killer)
end

--@summary Easy Access PlayerDied GameType Extracted Functions
Gamemode.PlayerDiedGameType = {
    Round = Gamemode.PlayerDiedRound,
    Score = Gamemode.PlayerDiedScore,
    Timer = Gamemode.PlayerDiedTimer,
    Custom = Gamemode.PlayerDiedCustom
}

--@summary Called when a player kills themselves. Set to false to just run :PlayerDied()
function Gamemode:PlayerDiedIsKiller(player)
    -- in the 1v1 gamemode, if a player kills themself than the other player will win.
    return self:EndRound("RoundOverWon", self:PlayerGetOtherPlayer(player) or player, player)
end
--Gamemode.PlayerDiedIsKiller = false

--

--@summary Get the total PlayerCount of players in self.PlayerData.
function Gamemode:PlayerGetCount()
    local count = 0
    for i, v in pairs(self.PlayerData) do
        count += 1
    end
    return count
end

--@summary Get a table all of the Players in self.PlayerData
function Gamemode:PlayerGetAll()
    local plrs = {}
    for _, v in pairs(self.PlayerData) do
        table.insert(plrs, v.Player)
    end
    return plrs
end

--@summary Get a Player from self.PlayerData via index
-- This will not consistently return the same Player, recommended to be used only once per action.
function Gamemode:PlayerGetDataByNumberIndex(index)
    local count = 0
    for i, v in pairs(self.PlayerData) do
        count += 1
        if count == index then
            return v
        end
    end
    return false
end

--@summary Called when a Player Joins during a round.
-- if rounds_enabled = false, this is for when a player joins after the game has started.
function Gamemode:PlayerJoinedDuringRound(player)
    self:PlayerInit(player, true)
    self:GuiInit(player)
    self:PlayerSpawn(player)
end

--@summary 1v1 Utility Function for getting the other player in the game.
function Gamemode:PlayerGetOtherPlayer(player)
    for _, v in pairs(self.PlayerData) do
        if v.Player ~= player then
            return v.Player
        end
    end
    return false
end

--@summary 1v1 Utility Function for getting the other player in the game.
function Gamemode:PlayerGetOtherPlayerData(player)
    for _, v in pairs(self.PlayerData) do
        if v.Player ~= player then
            return v
        end
    end
    return false
end

--@summary 1v1 Utility Function for getting player spawns, weapons, abilities and health.
function Gamemode:GetRoundPlayerContent()
    local currentRound = self.GameData.Round.Current

    local spawns = {}
    local r1 = math.round(math.random(1000,2000)/1000)
    spawns[1] = DefaultSpawns["Spawn"..tostring(r1)]
    spawns[2] = DefaultSpawns["Spawn"..tostring(r1 == 1 and 2 or 1)]

    -- get weapon based on round
    local weapons
    
    if currentRound == 1 then
        weapons = _GetRandomWeaponsIn({self.GameVariables.weapon_pool.light_secondary})
    elseif currentRound == 2 then
        weapons = _GetRandomWeaponsIn({self.GameVariables.weapon_pool.secondary})
    elseif currentRound == 3 then
        weapons = _GetRandomWeaponsIn({self.GameVariables.weapon_pool.light_primary, self.GameVariables.weapon_pool.secondary})
    else
        weapons = _GetRandomWeaponsIn({
            self.GameVariables.weapon_pool.primary,
            math.random(1,2) == 1 and self.GameVariables.weapon_pool.secondary or self.GameVariables.weapon_pool.light_secondary
        })
    end

    local abilities = {"Dash"}
    local util = self.GameVariables.ability_pool.utility
    table.insert(abilities, util[math.random(1,#util)])
    return {spawns = spawns, weapons = weapons, abilities = abilities, shield = _GetRoundShield(self)}
end

--@summary 1v1 Utility Function for getting random weapons in select pools.
function _GetRandomWeaponsIn(tab)
    local weapons = {}
    for i, v in pairs(tab) do
        table.insert(weapons, string.lower(v[math.random(1,#v)]))
    end
    return weapons
end

--@summary 1v1 Utility Function for getting the helmet and shield of the round.
function _GetRoundShield(self: Types.Gamemode)
    local shield, helmet = self.GameVariables.starting_shield, self.GameVariables.starting_helmet
    if self.GameData.Round.Current == 1 then
        shield, helmet = 0, false
    elseif self.GameData.Round.Current == 2 then
        shield, helmet = 50, false
    end
    return {shield = shield, helmet = helmet}
end

--

--@summary Initialize gamemode gui for a player or all players
function Gamemode:GuiInit(plr: Player | "all")
    local plrs = plr == "all" and self:PlayerGetAll() or {plr}
    for _, player in pairs(plrs) do
        if self.Name == "1v1" then
            local c = DefaultGuis.GamemodeBar:Clone()
            CollectionService:AddTag(c, "DestroyOnClose")
            local enemyobj = Instance.new("ObjectValue")
            enemyobj.Name = "EnemyObject"
            enemyobj.Value = self:PlayerGetOtherPlayer(player)
            enemyobj.Parent = c
            c.Parent = player:WaitForChild("PlayerGui")
        end
    end
end

--@summary Ran when Gamemode is Stopped
function Gamemode:GuiClose()
    for _, v in ipairs(CollectionService:GetTagged("DestroyOnClose") or {}) do
        v:Destroy()
    end
end

--@summary Update the default gamemode bar for all players.
function Gamemode:GuiUpdateGamemodeBarAll(updateType: "UpdateScore" | "StartTimer" | "StopTimer", ...)
    for _, plrdata in pairs(self.PlayerData) do
        local gui = plrdata.Player:WaitForChild("PlayerGui"):FindFirstChild("GamemodeBar")
        if gui then
            if updateType == "UpdateScore" then
                gui.RemoteEvent:FireClient(plrdata.Player, "UpdateScore", plrdata.Score, self:PlayerGetOtherPlayerData(plrdata.Player).Score)
            else
                gui.RemoteEvent:FireClient(plrdata.Player, updateType, ...)
            end
        end
    end
end

--@summary Add a specified ScreenGui to player or all
function Gamemode:GuiAddScreenGui(screenGui: ScreenGui, player: Player | "all", tag: string?)
    local plrs = player == "all" and self:PlayerGetAll() or {player} -- play round over gui
    for i, v in pairs(plrs) do
        local c = screenGui:Clone()
        c.Enabled = true
        c.Parent = v:WaitForChild("PlayerGui")
        if tag then
            CollectionService:AddTag(c, tag)
        end
    end
end

--@summary Round over gui to player or all
function Gamemode:GuiRoundOver(player: Player | "all", winner: Player, loser: Player)
    self:GuiUpdateGamemodeBarAll("UpdateScore") -- update score
    local plrs = player == "all" and self:PlayerGetAll() or {player} -- play round over gui
    for _, v in pairs(plrs) do
        local c = DefaultGuis.RoundWonGui:Clone()
        c:SetAttribute("WinnerName", winner and winner.Name or "")
        c:SetAttribute("LoserName", loser and loser.Name or "")
        c.Parent = v:WaitForChild("PlayerGui")
        Debris:AddItem(c, 3)
    end
end

--@summary Game over gui to player or all
function Gamemode:GuiGameOver(player: Player | "all")
    local plrs = player == "all" and self:PlayerGetAll() or {player}
    for i, v in pairs(plrs) do
        
    end
end

--@summary Waiting for player gui
function Gamemode:GuiWaitingForPlayers(player: Player | "all", tag: string?)
    local plrs = player == "all" and self:PlayerGetAll() or {player}
    for _, v in ipairs(plrs) do
        local c = DefaultGuis.WaitingForPlayers:Clone()
        c.Parent = v:WaitForChild("PlayerGui")
        if tag then
            CollectionService:AddTag(c, tag)
        end
    end
end

--@summary Add Black Screen
function Gamemode:GuiBlackScreenAll(maxLength: number?, inLength: number?, outLength: number?, await: boolean?)
    maxLength = maxLength or 5
    inLength = inLength or 0.25
    outLength = outLength or 0.25
    for _, v in ipairs(self:PlayerGetAll()) do
        local c: ScreenGui = DefaultGuis.BlackScreen:Clone()
        c:SetAttribute("InLength", inLength)
        c:SetAttribute("OutLength", outLength)
        c:SetAttribute("MaxLength", maxLength)
        c.Parent = v:WaitForChild("PlayerGui")
        c.ResetOnSpawn = false
        CollectionService:AddTag(c, "BlackScreen")
        Debris:AddItem(c, maxLength + inLength + outLength)
    end
    if await then
        task.wait(inLength)
    end
end

--@summary Remove Black Screen
function Gamemode:GuiRemoveBlackScreen(player: Player | "all", await: boolean)
    local outLength
    if player == "all" then
        for _, ui in ipairs(CollectionService:GetTagged("BlackScreen")) do
            ui.Out:FireClient(ui.Parent.Parent)
            outLength = ui:GetAttribute("OutLength")
            Debris:AddItem(ui, 5)
        end
    else
        if player:WaitForChild("PlayerGui"):FindFirstChild("BlackScreen") then
            player:WaitForChild("PlayerGui").BlackScreen.Out:Fire()
            outLength = player:WaitForChild("PlayerGui").BlackScreen:GetAttribute("OutLength")
            Debris:AddItem(player:WaitForChild("PlayerGui").BlackScreen, 5)
        end
    end
    
    if await then
        task.wait(outLength)
    end
end

--@summary Enable/disable player/all 's MainMenu
function Gamemode:GuiMainMenu(player: Player | "all", enabled: boolean)
    local plrs = player == "all" and self:PlayerGetAll() or {player}
    for _, v in pairs(plrs) do
        EnableMainMenuRemote:FireClient(v, enabled)
    end
end

--@summary Update the leaderboard for all players
function Gamemode:GuiUpdateLeaderboardAll()
    for _, v in pairs(self.PlayerData) do

        local function updateLeaderboard()
            if v.Player:WaitForChild("PlayerGui"):FindFirstChild("Leaderboard") then
                v.Player:WaitForChild("PlayerGui").Leaderboard:WaitForChild("UpdateLeaderboardEvent"):FireAllClients(self.PlayerData)
            end
        end

        local succ = pcall(function()
            updateLeaderboard()
        end)

        if not succ then
            task.wait(1)
            updateLeaderboard()
        end
    end
end

--@summary Add the leaderboard to player or alls
function Gamemode:GuiAddLeaderboard(player: Player | "all")
    local plrs = player == "all" and self:PlayerGetAll() or {player}
    for _, v in pairs(plrs) do
        local gui = DefaultLeaderboard:WaitForChild("Leaderboard"):Clone()
        local scripts = {DefaultLeaderboard:WaitForChild("KeyboardInputConnect"):Clone(), DefaultLeaderboard:WaitForChild("UpdateLeaderboard"):Clone()}
        scripts[1].Parent, scripts[2].Parent = gui, gui
        gui.Parent = v:WaitForChild("PlayerGui")
    end
end

return Gamemode
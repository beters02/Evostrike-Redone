--[[

    The Main Gamemode Class
    The base configuration will give you a 1v1 gamemode.

    To create a new Gamemode, create a new Class as a child to this one, with the name set as the Gamemode Name.
    Create a Table within the class called "GameVariables" and set any custom variables you would like.
    Add any functionality by overriding a base function.

    ex: Check Deathmatch script.

]]

-- [[ CONFIGURATION ]]
local LobbyID = 11287185880

local GamemodeClasses = script:GetChildren()
function GamemodeClasses.Find(gamemode: string) for _, v in pairs(GamemodeClasses) do if not v:IsA("ModuleScript") then continue end if v.Name == gamemode then return v end end return false end

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Types = require(script.Parent:WaitForChild("Types"))
local EnableMainMenuRemote = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("EnableMainMenu")
local Teams = game:GetService("Teams")
local TeleportService = game:GetService("TeleportService")
local RoundTimer = require(script.Parent:WaitForChild("RoundTimer"))
local Framework = require(game.ReplicatedStorage:WaitForChild("Framework"))
--local Weapon = require(Framework.Module.server.weapon.pm_main)
local WeaponService = require(game.ReplicatedStorage.Services.WeaponService)
local Ability = require(Framework.Module.server.ability.pm_main)
local EvoPlayer = require(game.ReplicatedStorage.Modules.EvoPlayer)
local EvoMM = require(game.ReplicatedStorage.Modules.EvoMMWrapper)
local Tables = require(Framework.Module.lib.fc_tables)
local BotService = require(game.ReplicatedStorage:WaitForChild("Services"):WaitForChild("BotService"))

local DefaultSpawns = script:WaitForChild("Spawns")
local DefaultGuis = script:WaitForChild("Guis")
local DefaultBots = script:WaitForChild("Bots")
local BindableEvent = script.Parent:WaitForChild("BindableEvent")

local Gamemode = {} :: Types.Gamemode
Gamemode.__index = Gamemode

Gamemode.GameVariables = {
    minimum_players = 2,
    maximum_players = 2,
    teams_enabled = false,
    players_per_team = 1,

    bots_enabled = false,

    opt_to_spawn = false, -- should players spawn in automatically, or opt in on their own? (lobby)
    main_menu_type = "Default", -- the string that the main menu requests upon init, and that is sent out upon gamemode changed

    characterAutoLoads = false,
    respawns_enabled = false,
    respawn_length = 3,

    rounds_enabled = true,
    round_length = 60,
    round_end_condition = "playerEliminated" :: Types.RoundEndCondition, -- teamEliminated, playerEliminated, timerOnly, scoreReached
    round_end_timer_assign = "roundScore", -- roundScore, health, random, false

    -- if scoreReached
    round_score_to_win_round = 1,
    round_score_increment_condition = "kills", -- other

    overtime_enabled = true,
    overtime_round_score_to_win_game = 1,
    overtime_round_score_to_win_round = 1,

    game_score_to_win_game = 7,
    game_end_condition = "scoreReached", -- timerOnly

    queueFrom_enabled = false, -- Can a player queue while in this gamemode?
    queueTo_enabled = true,    -- Can a player queue into this gamemode while in a queueFrom enabled gamemode?

    kick_players_on_end = true,

    can_players_damage = true,
    starting_health = 100,
    starting_shield = 50,
    starting_helmet = true,

    start_with_knife = true,
    auto_equip_strongest_weapon = true,

    weapon_pool = {
        light_primary = {"vityaz"},
        primary = {"ak103", "acr"},

        light_secondary = {"glock17"},
        secondary = {"deagle"}
    },

    buy_menu_enabled = false, -- if buy menu is enabled, buy_menu_starting_loadout must also be set.
    buy_menu_add_bought_instant = false, -- should the weapon/ability be added instantly or when they respawn
    buy_menu_starting_loadout = {
        Weapons = {primary = "ak103", secondary = "glock17"},
        Abilities = {primary = "Dash", secondary = "LongFlash"}
    },


    --[[starting_weapons = {
        secondary = "glock17", primary = "ak47"
    },]]
    starting_weapons = false,

    --[[starting_abilities = {
        "Dash"
    },]]
    starting_abilities = false,

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

    gamemodeClass = setmetatable(gamemodeClass, Gamemode)
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
    if self.Status == "Paused" and self.GameVariables.rounds_enabled then
        self:StartRound()
        return
    end

    self.Status = "Running"

    if self.GameVariables.queueFrom_enabled then
        EvoMM:StartQueueService({"Deathmatch", "1v1"})
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
            for pi = 1, self.GameVariables.players_per_team do
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
        self:GuiBlackScreenAll(0.01, 0.5, true)
    end

    task.wait()
    
    self:GuiRemoveTagged("WaitingForPlayersHUD")
    self:GuiInit("all")

    if self.GameVariables.bots_enabled then
        for _, v in pairs(DefaultBots:GetChildren()) do
            BotService:AddBot({SpawnCFrame = v.PrimaryPart.CFrame})
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

    if self.GameVariables.rounds_enabled then
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

    --[[PlayerDiedRemote.OnServerEvent:Connect(function(player, killer)
        self:_PlayerDiedCore(player, killer)
    end)]]

    self:StartRound()
end

--@summary Pause the Gamemode.
function Gamemode:Pause()
end

--@summary End the Gamemode.
function Gamemode:Stop(bruteForce)
    if not bruteForce and self.Status == "Stopped" then
        error("Gamemode already stopped.")
        return false
    end

    if self.GameData.RoundTimer and (self.GameData.RoundTimer.Status == "Started" or self.GameData.RoundTimer.Stats == "Paused") then
        self:EndRound("Restart") -- Restart just does nothing for the RoundTimer result
    end

    for _, v in pairs(self.GameData.Connections) do
        v:Disconnect()
        print("DISCONNECTING " .. tostring(v))
    end

    self:GuiBlackScreenAll(0.5, 0.3, true)

    self:PlayerRemoveAll()

    task.spawn(function()
        EvoMM:StopQueueService()
    end)

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

    if self.GameVariables.rounds_enabled then
        
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
        if self.GameVariables.rounds_enabled then
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
        if self.GameVariables.rounds_enabled then
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
    self:GuiUpdateGamemodeBarAll("StopTimer")

    task.delay(3, function()
        for i, v in pairs(workspace:WaitForChild("Temp"):GetChildren()) do
            v:Destroy()
        end
    end)

    --[[Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()]]

    if self.GameData.Connections.PlayerDied then
        self.GameData.Connections.PlayerDied:Disconnect()
    end

    task.wait(3)

    for _, v in pairs(self.PlayerData) do
        pcall(function()
            if v.Player.Character and v.Player.Character.Humanoid then
                v.Player.Character.Humanoid:TakeDamage(1000)
            end
        end)
    end

    self:GuiBlackScreenAll(0.5, 0.5, true)

    self.GameData.Round.Status = "Ended"
    self.GameData.Round.Current += 1
    if result == "RoundOverWon" then
        return self:_RoundOverWonCore(winner, loser)
    elseif result == "RoundOverTimer" then
        return self:RoundOverTimer()
    end

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
    print('yes')
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
            self:_GameOverWonCore(winner, loser)
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

--@summary Called in :EndRound() when rounds_enabled = true and the timer runs out.
function Gamemode:RoundOverTimer()

    local roundEndAssign = self.GameVariables.round_end_timer_assign
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

--@summary Called in :RoundOverWon() when rounds_enabled = true and player has reached the maximum amount of rounds.
function Gamemode:GameOverWon(winner, loser)
    -- add a nice game over gui, then wait 3 seconds before players are kicked.
    self:GuiGameOver("all", winner)
    task.wait(5)
end

--@final
--@summary
function Gamemode._GameOverWonCore(self, winner, loser)
    self:GameOverWon(winner, loser)

    if self.GameVariables.kick_players_on_end then
        TeleportService:TeleportAsync(LobbyID, self:PlayerGetAll())
        return
    end

    -- this event will handle stopping and restarting in GamemodeService.
    BindableEvent:Fire("GameRestart")
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
            self:GuiWaitingForPlayers(player, "WaitingForPlayersHUD")
        end
    end)
    
    self.PlayerData[player.Name] = {
        Player = player,
        Kills = 0,
        Deaths = 0
    }

    if self.GameVariables.buy_menu_enabled then
        self.PlayerData[player.Name].BuyMenuLoadout = Tables.clone(self.GameVariables.buy_menu_starting_loadout)
    end

    if self.GameVariables.rounds_enabled then
        self.PlayerData[player.Name].Score = 0
    end

    if self.GameVariables.round_end_condition == "scoreReached" then
        self.PlayerData[player.Name].Round = {Score = 0}
    end
end

--@summary Spawn a player. Called either in PlayerSpawnAll() or during respawn on PlayerDied()
function Gamemode:PlayerSpawn(player, content, index)
    player:LoadCharacter()
    task.wait()
    player.Character:SetPrimaryPartCFrame(content and content.spawns[index].CFrame or DefaultSpawns.Default.CFrame)

    player.Character:WaitForChild("Humanoid").Health = self.GameVariables.starting_health
    local shield, helmet = self.GameVariables.starting_shield, self.GameVariables.starting_helmet

    local strongestWeapon = "ternary"
    local bml = self.PlayerData[player.Name].BuyMenuLoadout

    if self.GameVariables.auto_equip_strongest_weapon then
        if bml then
            strongestWeapon = bml.primary and "primary" or "secondary"
        else
            if self.GameVariables.starting_weapons then
                strongestWeapon = self.GameVariables.starting_weapons.primary and "primary" or "secondary"
            end
        end
    end
   

    if self.GameVariables.start_with_knife then
        WeaponService:AddWeapon(player, "Knife", strongestWeapon == "ternary")
    end

    if self.PlayerData[player.Name].BuyMenuLoadout then
        for i, v in pairs(self.PlayerData[player.Name].BuyMenuLoadout.Weapons) do
            WeaponService:AddWeapon(player, v, strongestWeapon == i)
        end
        for _, v in pairs(self.PlayerData[player.Name].BuyMenuLoadout.Abilities) do
            Ability.Add(player, v)
        end
    else
        if self.GameVariables.starting_weapons then
            for i, v in pairs(self.GameVariables.starting_weapons) do
                WeaponService:AddWeapon(player, v, strongestWeapon == i)
            end
        end
        if self.GameVariables.starting_abilities then
            for _, v in pairs(self.GameVariables.starting_abilities) do
                Ability.Add(player, v)
            end
        end
    end

    if self.GameVariables.buy_menu_enabled then
        self:GuiAddBuyMenu(player)
    end

    if self.Name == "1v1" then
        for _, v in pairs(content.weapons) do
            WeaponService:AddWeapon(player, v)
        end
        task.delay(0.9, function()
            for _, v in pairs(content.abilities) do
                Ability.Add(player, v)
            end
        end)
        shield, helmet = content.shield.shield, content.shield.helmet
    end

    EvoPlayer:SetShield(player.Character, shield)
    EvoPlayer:SetHelmet(player.Character, helmet)
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
function Gamemode:PlayerDied(player, killer)
    --TODO: add the death camera script here
end

--@final
--@summary For win conditioning, respawns, etc. Called by default when a Player dies. Not recommended to override.
function Gamemode._PlayerDiedCore(self, player, killer)
    self:PlayerDied(player, killer)

    if self.GameVariables.respawns_enabled then
        task.delay(self.GameVariables.respawn_length, function()
            self:PlayerSpawn(player)
            print("Respawning!!!")
        end)
    end

    local tagged = CollectionService:GetTagged(player.Name .. "ClearOnDeath")
    if tagged then
        for _, v in pairs(tagged) do
            v:Destroy()
        end
    end

    if self.GameVariables.buy_menu_enabled then
        local pd = self.PlayerData[player.Name]
        if pd.BuyMenu then pd.BuyMenu:Destroy() end
        if pd.BuyMenuConnections then
            for _, v in pairs(pd.BuyMenuConnections) do
                v:Disconnect()
            end
        end
        
        self.PlayerData[player.Name].BuyMenu = nil
        self.PlayerData[player.Name].BuyMenuConnections = nil
    end

    if self.GameVariables.rounds_enabled then
        if killer and killer == player or not killer then
            if self.PlayerDiedIsKiller then
                return self:PlayerDiedIsKiller(player)
            end
        elseif self.GameVariables.round_end_condition == "scoreReached" and self.GameVariables.round_score_increment_condition == "kills" then
            if not self.PlayerData[killer.Name].Round.Score then
                self.PlayerData[killer.Name].Round.Score = 0
            end
            self.PlayerData[killer.Name].Round.Score += 1
        end
        if self.GameVariables.round_end_condition == "playerEliminated" then
            return self:EndRound("RoundOverWon", killer, player)
        end
        if self.GameVariables.round_end_condition == "teamEliminated" then
            -- check alive status of team members
            local aliveTeamMembers = 0
            if aliveTeamMembers <= 0 then
                return self:EndRound("RoundOverWonTeam", killer, player)
            end
        end
        if self.GameVariables.round_end_condition == "scoreReached" then
            if self.PlayerData[killer.Name].Round.Score == self.GameVariables.round_score_to_win_round then
                return self:EndRound("RoundOverWon", killer, player)
            end
        end
        return true
    end
end

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
    table.insert(abilities, math.round(math.random(1000,2000)/1000) == 1 and "LongFlash" or "Molly")
    
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
            local enemyobj = Instance.new("ObjectValue")
            enemyobj.Name = "EnemyObject"
            enemyobj.Value = self:PlayerGetOtherPlayer(player)
            enemyobj.Parent = c
            c.Parent = player.PlayerGui
        end
    end
end

--@summary Update the default gamemode bar for all players.
function Gamemode:GuiUpdateGamemodeBarAll(updateType: "UpdateScore" | "StartTimer" | "StopTimer", ...)
    for _, plrdata in pairs(self.PlayerData) do
        local gui = plrdata.Player.PlayerGui:FindFirstChild("GamemodeBar")
        if gui then
            if updateType == "UpdateScore" then
                gui.RemoteEvent:FireClient(plrdata.Player, "UpdateScore", plrdata.Score, self:PlayerGetOtherPlayerData(plrdata.Player).Score)
                print('updating score!')
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
        c.Parent = v.PlayerGui
        if tag then
            CollectionService:AddTag(c, tag)
        end
    end
end

--@summary Add a BuyMenu and it's connections to a player or all.
function Gamemode:GuiAddBuyMenu(player: Player | "all")
    local plrs = player == "all" and self:PlayerGetAll() or {player} -- play round over gui
    for _, v in pairs(plrs) do
        local c = DefaultGuis.BuyMenu:Clone()
        c.Enabled = false
        c.Parent = v.PlayerGui

        if self.PlayerData[player.Name].BuyMenu then
            self.PlayerData[player.Name].BuyMenu:Destroy()
        end

        self.PlayerData[player.Name].BuyMenu = c
        
        if not self.PlayerData[player.Name].BuyMenuConnections then
            self.PlayerData[player.Name].BuyMenuConnections = {}
        elseif #self.PlayerData[player.Name].BuyMenuConnections > 0 then
            for conni, conn in pairs(self.PlayerData[player.Name].BuyMenuConnections) do
                conn:Disconnect()
                self.PlayerData[player.Name].BuyMenuConnections[conni] = nil
            end
        end

        self.PlayerData[player.Name].BuyMenuConnections.Ability = c.AbilitySelected.OnServerEvent:Connect(function(_, abilityName, abilitySlot)
            print(abilityName)
            self.PlayerData[player.Name].BuyMenuLoadout.Abilities[abilitySlot] = abilityName
            if self.GameVariables.buy_menu_add_bought_instant then
                Ability.Add(player, abilityName)
            end
        end)

        self.PlayerData[player.Name].BuyMenuConnections.Weapon = c.WeaponSelected.OnServerEvent:Connect(function(_, weaponName, weaponSlot)
            self.PlayerData[player.Name].BuyMenuLoadout.Weapons[weaponSlot] = weaponName
            if self.GameVariables.buy_menu_add_bought_instant then
                WeaponService:AddWeapon(player, weaponName)
            end
        end)
    end
end

--@summary Round over gui to player or all
function Gamemode:GuiRoundOver(player: Player | "all")
    self:GuiUpdateGamemodeBarAll("UpdateScore") -- update score
    local plrs = player == "all" and self:PlayerGetAll() or {player} -- play round over gui
    for i, v in pairs(plrs) do
        
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
    for i, v in pairs(plrs) do
        local c = DefaultGuis.WaitingForPlayers:Clone()
        c.Parent = v.PlayerGui
        if tag then
            CollectionService:AddTag(c, tag)
        end
    end
end

--@summary Add Black Screen
function Gamemode:GuiBlackScreenAll(inLength: number?, outLength: number?, await: boolean?)
    inLength = inLength or 0.25
    outLength = outLength or 0.25
    for _, v in pairs(self:PlayerGetAll()) do
        local c: ScreenGui = DefaultGuis.BlackScreen:Clone()
        c:SetAttribute("InLength", inLength)
        c:SetAttribute("OutLength", outLength)
        c.Parent = v.PlayerGui
        c.ResetOnSpawn = false
        CollectionService:AddTag(c, "BlackScreen")
    end
    if await then
        task.wait(inLength)
    end
end

--@summary Remove Black Screen
function Gamemode:GuiRemoveBlackScreen(player: Player | "all", await: boolean)
    local outLength
    if player == "all" then
        for _, ui in pairs(CollectionService:GetTagged("BlackScreen")) do
            ui.Out:FireClient(ui.Parent.Parent)
            outLength = ui:GetAttribute("OutLength")
            Debris:AddItem(ui, 5)
        end
    else
        if player.PlayerGui:FindFirstChild("BlackScreen") then
            player.PlayerGui.BlackScreen.Out:Fire()
            outLength = player.PlayerGui.BlackScreen:GetAttribute("OutLength")
            Debris:AddItem(player.PlayerGui.BlackScreen, 5)
        end
    end
    
    if await then
        task.wait(outLength)
    end
end

--@summary Remove all tagged UIs from the workspace.
function Gamemode:GuiRemoveTagged(tag: string)
    for _, ui in pairs(CollectionService:GetTagged(tag)) do
        ui:Destroy()
    end
end

--@summary Enable/disable player/all 's MainMenu
function Gamemode:GuiMainMenu(player: Player | "all", enabled: boolean)
    local plrs = player == "all" and self:PlayerGetAll() or {player}
    for _, v in pairs(plrs) do
        EnableMainMenuRemote:FireClient(v, enabled)
    end
end

return Gamemode
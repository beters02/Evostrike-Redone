--[[
    Purpose:
    Reorganize Gamemode Class.

    The first Gamemode Class was a good start but overall it's very unorganized which actually lead to a lot of problems.
    The problems were very fixable but I know if I just recreate the Class with more organization it will make QOL much better.

    Gamemode Functions that are capitalized and start with _ are meant to be overridden in gamemode classes.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RoundTimer = require(script.Parent.Parent:WaitForChild("RoundTimer"))
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local EvoPlayer = require(Framework.Module.EvoPlayer)
local Tables = require(Framework.Module.lib.fc_tables)
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)

--[[ GAME_TYPE

    All game_type's except Custom will have a RoundTimer and work with the Round system.
    
    game_type Round
        - Multiple rounds with GameEndCondition being rounds won (score_to_win)
        - round_end_condition :: "PlayerKilled" | "TeamKilled" | "ScoreReached" | "Timer"
        - if round_end_condition is ScoreReached, score_increment_condition can be set.
        - TeamKilled only works if teams_enabled = true

    game_type Score
        - One round with GameEndCondition being score reached (score_to_win)
        - score_increment_condition :: "Kill" | "Custom"

    game_type Custom
        - Empty gamemode with no timer and no end condition.

]]

--[[ TAGS

    GamemodeDestroyOnStop
    GamemodeDestroyOnRoundOver
    GamemodeDestroyOnPlayerDied_{playerName}

]]
--

-- [[ TYPE DEF ]]
local Types = require(script.Parent.Parent:WaitForChild("Types"))
type GamemodeStatus = "Running" | "Stopped" | "Dead"
type GameType = "Round" | "Score" | "Custom"
type RoundOverResult = "Timer" | "Condition"
type PlayerData = {Name: string, Player: Player, Kills: number, Deaths: number, Damage: number, Loadout: table}
local PlayerData = {}
function PlayerData.new(player, loadout) return {Name = player.Name, Player = player, Kills = 0, Deaths = 0, Damage = 0, Loadout = loadout} :: PlayerData end
--

-- [[ GAMEMODE CLASS VAR ]]
local Gamemode = {
    GameVariables = {
        -- [[ GENERAL ]]
        game_type = "Round" :: Types.GameType,
        minimum_players = 2,
        maximum_players = 2,
        bots_enabled = false,
        leaderboard_enabled = true,
        --spawn_objects = DefaultSpawns,

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
}
Gamemode.Status = "Stopped"
Gamemode.Timer = false
Gamemode.Connections = {}
Gamemode.PlayerData = {}
Gamemode.BaseModule = script
--

--@class
function Gamemode.new(gamemode)
    local gamemodeModule = script.Parent:FindFirstChild(gamemode)
    assert(gamemodeModule, "Cannot create GamemodeClass " .. tostring(gamemode) .. ". Gamemode must have a Gamemode Module")

    local self = setmetatable(require(gamemodeModule), Gamemode)
    self.Name = gamemode
    self.Module = gamemodeModule

    return self
end

function Gamemode:Start()
    assert(self.Status ~= "Dead", "Cannot start Gamemode from Dead state.")
    assert(self.Status ~= "Running", "Gamemode is already running.")
    self.Status = "Running"
    print("Starting " .. tostring(self.Name))

    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player) self:PlayerJoined(player) end)
    self.Connections.PlayerDied = Framework.Module.EvoPlayer.Events.PlayerDiedRemote.OnServerEvent:Connect(function(died, killer) self:PlayerDied(died, killer) end)

    if self.GameVariables.queueFrom_enabled then
        -- start queueservice
    end

    if self.GameVariables.buy_menu_enabled then
        -- start buymenuservice
    end

    self:RoundStart()
end

function Gamemode:Stop()
    assert(self.Status == "Running", "Cannot stop an already stopped Gamemode.")
    self.Status = "Dead"
    self:Cleanup()
end

--[[ROUNDS SCOPE]]

-- [[ ROUND START ]]
--@summary Starts a Round.
function Gamemode:RoundStart()
    self:_RoundInitStart()

    self:PlayerSpawnAll()

    -- round timer
    if self.GameVariables.game_type ~= "Custom" then
        self:CreateRoundTimer(self.GameVariables.round_length)
        self.Timer:Start()
        self.Connections.Timer = self.Timer.Finished:Once(function()
            self:RoundOver("Timer")
        end)
    end

    self:_RoundFinishStart()
end

--@summary Called at the beinning of Rounds:Start()
function Gamemode:_RoundInitStart()
end

--@summary Called at the end of Rounds:Start()
function Gamemode:_RoundFinishStart()
end
--

-- [[ ROUND OVER ]]
--@summary Called when round is determined to be over.
function Gamemode:RoundOver(result: RoundOverResult, winner)
    self:_RoundInitOver()
    self:_RoundFinishOver()

    local startNext
    if result == "Timer" then
        startNext = self:_RoundEndedBecauseOfTimer()
    else
        startNext = self:_RoundEndedBecauseOfCondition(winner)
    end

    if startNext then
        self:RoundStart()
    end
end

--@summary Called at the beginning of RoundOver
function Gamemode:_RoundInitOver()
end

--@summary Called at the end of RoundOver before GameOver is determined
function Gamemode:_RoundFinishOver()
end

function Gamemode:_RoundEndedBecauseOfTimer()
    return true
end

function Gamemode:_RoundEndedBecauseOfCondition(winner) -- Returns startNext boolean
    if self.GameVariables.game_type == "Score" then
        self:GameOver(winner)
        return false
    else
        self.PlayerData[winner.Name].Score += 1
        if self.PlayerData[winner.Name].Score >= self.GameVariables.score_to_win then
            self:GameOver(winner)
            return false
        end
    end
    return true
end

--

--[[ GAME OVER ]]

--@summary Called in :RoundOver when game is determined to be finished.
function Gamemode:GameOver()
    self:_GameInitOver()

    self:_GameFinishOver()
end

--@summary Called in the beginning of GameOver
function Gamemode:_GameInitOver()
    
end

--@summary Called at the end of GameOver before Kick/Restart is determined
function Gamemode:_GameFinishOver()
    
end

--

--[[PLAYERS SCOPE]]

function Gamemode:PlayerInitData(player)
    if not self.PlayerData[player.Name] then
        self.PlayerData[player.Name] = PlayerData.new(player)
        
        -- init loadout
        if self.GameVariables.buy_menu_enabled then
            self.PlayerData[player.Name].Loadout = Tables.clone(self.GameVariables.buy_menu_starting_loadout)
        else
            self.PlayerData[player.Name].Loadout = {Weapons = Tables.clone(self.GameVariables.starting_weapons), Abilities = Tables.clone(self.GameVariables.starting_abilities)}
        end
    end
end

function Gamemode:_PlayerInitGui(player)
    
end

--@summary
function Gamemode:PlayerJoined(player)
    self:PlayerInitData(player)
    self:_PlayerInitGui(player)
end

-- [[ PLAYER DIED ]]
--@summary
function Gamemode:PlayerDied(player, killer)
    self:_InitPlayerDied(player, killer)

    self.PlayerData[player.Name].Deaths += 1

    if killer and player ~= killer then
        self.PlayerData[killer.Name].Kills += 1

        if self.GameVariables.game_type == "Round" then
            if self.GameVariables.round_end_condition == "ScoreReached" then
                self.PlayerData[killer.Name].Round.Score += 1
                if self.PlayerData[killer.Name].Round.Score >= self.GameVariables.round_score_to_win_round then
                    self:RoundOver("Condition", killer)
                    return
                end
            elseif self.GameVariables.round_end_condition == "PlayerKilled" then
                self:RoundOver("Condition", killer)
                return
            elseif self.GameVariables.round_end_condition == "TeamKilled" then
                -- if not _IsTeamAlive() self:RoundOver("Condition")
            end
        end

    end

    self:_FinishPlayerDied(player, killer)
end

function Gamemode:_InitPlayerDied(player, killer)
    
end

function Gamemode:_FinishPlayerDied(player, killer)
    
end
--

--@summary Called in RoundStart
function Gamemode:PlayerSpawnAll()
    for _, v in pairs(Players:GetPlayers()) do
        self:PlayerSpawn(v)
    end
end

--@summary Called when a Player is to be spawned.
function Gamemode:PlayerSpawn(player)
    local spawnCF = self:PlayerGetSpawnPoint()

    player:LoadCharacter()
    task.wait()

    player.Character:SetPrimaryPartCFrame(spawnCF)
    self:PlayerAddWeapons(player)
    self:PlayerAddAbilities(player)
end

function Gamemode:PlayerGetSpawnPoint()
    
end

function Gamemode:PlayerAddWeapons(player)
    local playerdata = self.PlayerData[player.Name]
    local strongest = false
    if self.GameVariables.auto_equip_strongest_weapon then
        strongest = playerdata.Loadout.Weapons.primary or playerdata.Loadout.Weapons.secondary or "knife"
    end

    if self.GameVariables.start_with_knife then
        WeaponService:AddWeapon(player, "knife", not strongest and true or strongest == "knife")
    end

    for _, v in pairs(playerdata.Loadout.Weapons) do
        WeaponService:AddWeapon(player, v, strongest and strongest == v)
    end
end

function Gamemode:PlayerAddAbilities(player)
    local playerdata = self.PlayerData[player.Name]
    for _, v in pairs(playerdata.Loadout.Abilities) do
        AbilityService:AddAbility(player, v)
    end
end

--[[GUI SCOPE]]

--@summary Add a GuiScript from the Guis folder
function Gamemode:GuiAdd(player, gui: string)
    local guiscript = self.Module.Guis:FindFirstChild(gui) or self.BaseModule.Guis:FindFirstChild(gui)
    assert(guiscript, "Could not add gui " .. tostring(gui) .. " gui not found in either Guis folders.")
    guiscript:Clone().Parent = player:WaitForChild("PlayerGui")
    return guiscript
end

function Gamemode:GuiAddAll(gui: string)
    for _, v in pairs(Players:GetPlayers()) do
        self:GuiAdd(v, gui)
    end
end

--[[UTILITY SCOPE]]

function Gamemode:CreateRoundTimer(length)
    if self.Timer then
        self.Timer:Stop("Restart")
        self.Timer = false
    end
    self.Timer = RoundTimer.new(length)
    return self.Timer
end

--@summary Destroys all Gamemode-Related objects and disconnects all connections.
function Gamemode:Cleanup()
    self:ClearTagged("GamemodeDestroyOnRoundOver")
    self:ClearTagged("GamemodeDestroyOnStop")
    task.spawn(function()
        for _, v in ipairs(Players:GetPlayers()) do
            self:ClearTagged("GamemodeDestroyOnPlayerDied_" .. v.Name)
        end
    end)
    workspace.Temp:ClearAllChildren()
    if self.Timer then
        self.Timer:Stop("Restart")
    end
end

function Gamemode:ClearTagged(tag)
    for _, v in ipairs(CollectionService:GetTagged(tag)) do
        v:Destroy()
        v = nil
    end
end

function Gamemode:Disconnect()
    for _, v in pairs(self.Connections) do
        v:Disconnect()
    end
    table.clear(self.Connections)
end

function Gamemode:GetStrongestWeaponFromLoadout(loadout)
    
end

return Gamemode
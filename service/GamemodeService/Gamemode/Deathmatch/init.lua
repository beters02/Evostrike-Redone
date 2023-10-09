--  In this Deathmatch gamemode, players will spawn at a random point in the points array.
--  Players need to reach a score of 100 to win the game. Respawns are enabled.
--  (Players will recieve 1 game point after getting 100 kills in the round, winning them the game.)

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local DMGuis = script:WaitForChild("Guis")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local EvoEconomy = require(Framework.Module.EvoEconomy)

local Deathmatch = {}

Deathmatch.GameVariables = {
    -- [[ GENERAL ]]
    game_type = "Timer",
    minimum_players = 1,
    maximum_players = 8,
    bots_enabled = false,
    leaderboard_enabled = true,

    -- [[ QUEUING ]]
    queueFrom_enabled = true, -- Can a player queue while in this gamemode?
    queueTo_enabled = false,    -- Can a player queue into this gamemode while in a queueFrom enabled gamemode?

    -- [[ MAIN MENU ]]
    main_menu_type = "Lobby", -- the string that the main menu requests upon init, and that is sent out upon gamemode changed

    -- [[ TEAMS ]]
    teams_enabled = false,
    players_per_team = 1,

    -- [[ ROUDS ]]
    round_length = 10 * 60, -- in sec

    -- [[ PLAYER SPAWNING ]]
    opt_to_spawn = true,           -- should players spawn in automatically, or opt in on their own? (lobby)
    characterAutoLoads = false,     -- roblox CharacterAutoLoads
    respawns_enabled = false,
    respawn_length = 3,
    spawn_invincibility = 3,        -- set to false for none
    starting_health = 100,
    starting_shield = 50,
    starting_helmet = true,

    -- [[ GAME END CONDITIONS ]]
    kick_players_on_end = false,             -- Kick players or Restart game?

    -- [[ WEAPONS & DAMAGING ]]
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

    buy_menu_enabled = true, -- if buy menu is enabled, buy_menu_starting_loadout must also be set.
    buy_menu_add_bought_instant = false, -- should the weapon/ability be added instantly or when they respawn
    buy_menu_starting_loadout = {
        Weapons = {primary = "ak103", secondary = "glock17"},
        Abilities = {primary = "Dash", secondary = "LongFlash"}
    },

    starting_weapons = false,
    starting_abilities = false,

    game_over_next_game_length = 15,
}

-- [[ Override Gamemode Class Functions ]]
Deathmatch.PlayerDiedIsKiller = false

--@summary Initialize gamemode gui for a player or all players
function Deathmatch:GuiInit(_reqPlr: Player | "all")
    local plrs = _reqPlr == "all" and self:PlayerGetAll() or {_reqPlr}
    for _, player in pairs(plrs) do
        local att = {}
        if self.GameData.RoundTimer and self.GameData.RoundTimer.Time then
            att.TimerTime = self.GameData.RoundTimer.Time
        else
            att.TimerTime = self.GameVariables.round_length
        end
        if not self.PlayerData[player.Name] then
            repeat task.wait() until self.PlayerData[player.Name]
        end
        self.PlayerData[player.Name].TopBarScript = self:AddDMGui(player, "TopBar", false, att)
    end
end

function Deathmatch:PlayerDied(player, killer)
    local killedStr = "You died!"

    if killer and player.Name ~= killer.Name then
        killedStr = killer.Name .. " killed you!"
        if self.PlayerData[killer.Name].TopBarScript then
            self.PlayerData[killer.Name].TopBarScript:WaitForChild("Events").RemoteEvent:FireClient(killer, "UpdateScoreFrame", self.PlayerData[killer.Name].Kills)
        end
    end

    if self.PlayerData[player.Name].TopBarScript then
        self.PlayerData[player.Name].TopBarScript:WaitForChild("Events").RemoteEvent:FireClient(player, "UpdateScoreFrame", false, self.PlayerData[player.Name].Deaths)
    end

    local _diedguiscript, _diedgui = self:AddDMGui(player, "PlayerDied", false, {KilledString = killedStr})
    local _diedconn
    _diedconn = _diedguiscript:WaitForChild("Events"):WaitForChild("RemoteEvent").OnServerEvent:Connect(function(_plr, action)
        if _plr ~= player then warn("Players dont match PlayerMenuRespawn??") end
        if action == "Respawn" then
            _diedgui:Destroy()
            _diedguiscript:Destroy()
            self:PlayerSpawn(player)
            _diedconn:Disconnect()
        end
    end)
end

function Deathmatch:GameOver()
    print('Game Over!')
    local endt = tick() + self.GameVariables.game_over_next_game_length
    local gmPlayerStats = self:SortPlayersByScore() -- {{name, kills, deaths}}
    local top3 = self:GetTop3(gmPlayerStats)

    local addedUIs = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local _stats = self:CalculatePlayerPostMatchStats(plr, self:IsTop3(plr, top3))
        local guiScript = self:AddDMGui(plr, "GameOver", false, {EarnedStrafeCoins = _stats.StrafeCoins, EarnedXP = _stats.XP, TimerLength = self.GameVariables.game_over_next_game_length})
        task.spawn(function()
            guiScript:WaitForChild("Events"):WaitForChild("RemoteEvent"):FireClient(plr, self.PlayerData)
        end)
        table.insert(addedUIs, {plr, guiScript})
    end
    
    local t
    repeat t = tick() task.wait() until t >= endt

    for _, uiobj in ipairs(addedUIs) do
        task.spawn(function()
            uiobj[2]:WaitForChild("Events"):WaitForChild("RemoteFunction"):InvokeClient(uiobj[1])
            task.delay(2, function()
                uiobj[2]:Destroy()
                uiobj = nil
            end)
        end)
    end

    task.wait(1)
    addedUIs = nil
end

-- [[ Deathmatch Class Functions ]]
type PlayerPostMatchStats = {StrafeCoins: number, XP: number}
function Deathmatch:CalculatePlayerPostMatchStats(player, isTop3)
    local playerdata = self.PlayerData[player.Name]
    if not playerdata then return end

    -- func var
    local kills = playerdata.Kills
    local deaths = playerdata.Deaths
    local xp = 100
    local sc = 5
    --local pc = 0

    local hasKd = math.ceil(kills/deaths) >= 1

    -- Calculation
    if isTop3 then
        xp += 100
        sc += 5
    end

    if hasKd then
        xp += 100
        sc += 5
    end

    local datasucc, dataresult = pcall(function()
        EvoEconomy:Increment(player, "StrafeCoins", sc)
        EvoEconomy:Increment(player, "XP", xp)
        EvoEconomy:Save(player)
    end)
    if not datasucc then
        warn("Could not set " .. player.Name .. " DataStore Stats. " .. tostring(dataresult))
    end

    return {StrafeCoins = sc, XP = xp}
end

function Deathmatch:PlayerGetSpawnPoint()
    local points = {}
    local lowest
    local spawns

    -- if we have a small player count, we want to only spawn
    -- them in zone 1 which will be a smaller area of the map

    -- get spawn location in zones based on amount of players in game
    if self:PlayerGetCount() <= 0.5 * self.GameVariables.maximum_players then
        spawns = self.GameVariables.spawn_objects.Zone1:GetChildren()
    else
        spawns = {self.GameVariables.spawn_objects.Zone1:GetChildren(), self.GameVariables.spawn_objects.Zone2:GetChildren()}
    end

    for _, v in pairs(Players:GetPlayers()) do
        if not v.Character then continue end

        for _, spwn in pairs(spawns) do
            if spwn:IsA("Part") then
                if not points[spwn.Name] then points[spwn.Name] = 10000 end
                points[spwn.Name] -= (v.Character.HumanoidRootPart.CFrame.Position - spwn.CFrame.Position).Magnitude

                if not lowest or points[spwn.Name] < lowest[2] then
                    lowest = {spwn, points[spwn.Name]}
                end
            end
        end
    end

    lowest = lowest and lowest[1] or spawns[math.random(1, #spawns)]
    return lowest.CFrame
end

function Deathmatch:PlayerJoinedDuringRound(player)
    self:PlayerInit(player)
    self:GuiInit(player)
    self:GuiMainMenu(player, true)
end

function Deathmatch:AddDMGui(player: Player, guiName: string, resetOnSpawn: boolean?, attributes: table?)
    local guiScript = DMGuis:FindFirstChild(guiName)
    if not guiScript then
        error("Could not find Deathmatch Gui " .. tostring(guiName))
    end

    local parent = player:WaitForChild("PlayerGui"):WaitForChild("Container")
    guiScript = guiScript:Clone() :: ScreenGui
    CollectionService:AddTag(guiScript, "DestroyOnClose")
    guiScript:WaitForChild("Gui").ResetOnSpawn = resetOnSpawn or false

    if attributes then
        for i, v in pairs(attributes) do
            guiScript:SetAttribute(i, v)
        end
    end

    guiScript.Parent = parent
    return guiScript, guiScript.Gui
end

-- [[ Utility ]]    PlayerStats array = {string(PlayerName), number(Kills), number(Deaths)}

function Deathmatch:SortPlayersByScore() -- Returns Sorted Array of PlayerStats
    local scores = {}
    for name, data in pairs(self.PlayerData) do
        if table.find(scores, name) then continue end
        scores = self:ScoreSortPlayer(name, data, scores)
    end
    return scores
end

function Deathmatch:ScoreSortPlayer(name, data, scores)
    if #scores == 0 then
        scores[1] = {name, data.Kills, data.Deaths}
        return scores
    end
    for sindex, sobj in scores do
        if data.Score > self.PlayerData[sobj[1]].Score then
            local _c = sobj
            scores[sindex] = {name, data[2], data[3]}
            scores[sindex+1] = _c
            break
        end
    end
    return scores
end

function Deathmatch:GetTop3(sortedPlayers) -- Returns PlayerNames
    local top3Names = {}
    for i = 1,3 do
        if not sortedPlayers[i] then break end
        table.insert(top3Names, sortedPlayers[i][1])
    end
    return top3Names
end

function Deathmatch:IsTop3(player, top3)
    return table.find(top3, player.Name) and true or false
end

return Deathmatch
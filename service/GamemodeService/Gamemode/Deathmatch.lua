--  In this Deathmatch gamemode, players will spawn at a random point in the points array.
--  Players need to reach a score of 100 to win the game. Respawns are enabled.
--  (Players will recieve 1 game point after getting 100 kills in the round, winning them the game.)

local Players = game:GetService("Players")

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
    round_length = 30 * 60,

    -- [[ PLAYER SPAWNING ]]
    opt_to_spawn = true,           -- should players spawn in automatically, or opt in on their own? (lobby)
    characterAutoLoads = false,     -- roblox CharacterAutoLoads
    respawns_enabled = true,
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
    starting_abilities = false
}

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
    self:GuiMainMenu(player, true)
end

-- Don't do anything special when a player kills themself
Deathmatch.PlayerDiedIsKiller = false

return Deathmatch
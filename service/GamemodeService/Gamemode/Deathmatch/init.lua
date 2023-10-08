--  In this Deathmatch gamemode, players will spawn at a random point in the points array.
--  Players need to reach a score of 100 to win the game. Respawns are enabled.
--  (Players will recieve 1 game point after getting 100 kills in the round, winning them the game.)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local DMGuis = script:WaitForChild("Guis")

local Deathmatch = {}

Deathmatch.GameVariables = {
    minimum_players = 1,
    maximum_players = 8,
    
    buy_menu_enabled = true,
    main_menu_type = "Lobby",

    rounds_enabled = true,
    round_end_condition = "scoreReached",
    round_end_timer_assign = "roundScore",

    -- if scoreReached
    round_score_to_win_round = 500,
    round_score_increment_condition = "kills", -- other

    overtime_enabled = false,

    game_score_to_win_game = 1,
    game_end_condition = "scoreReached",

    queueFrom_enabled = true, -- Can a player queue while in this gamemode?
    queueTo_enabled = false,    -- Can a player queue into this gamemode while in a queueFrom enabled gamemode?

    kick_players_on_end = false,

    -- [[ TEAMS ]]
    teams_enabled = false,
    players_per_team = 1,

    -- [[ ROUDS ]]
    round_length = 30 * 60,

    -- [[ PLAYER SPAWNING ]]
    opt_to_spawn = true,           -- should players spawn in automatically, or opt in on their own? (lobby)
    characterAutoLoads = false,     -- roblox CharacterAutoLoads
    respawns_enabled = false,
    respawn_length = 5,
    spawn_invincibility = 3,        -- set to false for none
    starting_health = 100,
    starting_shield = 50,
    starting_helmet = true
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

--@summary Initialize gamemode gui for a player or all players
function Deathmatch:GuiInit(_reqPlr: Player | "all")
    local plrs = _reqPlr == "all" and self:PlayerGetAll() or {_reqPlr}
    for _, player in pairs(plrs) do
        local att = {}
        if self.GameData.RoundTimer and self.GameData.RoundTimer.Time then
            att.TimerTime = self.GameData.RoundTimer.Time
            print(self.GameData.RoundTimer.Time)
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

-- Don't do anything special when a player kills themself
Deathmatch.PlayerDiedIsKiller = false

return Deathmatch
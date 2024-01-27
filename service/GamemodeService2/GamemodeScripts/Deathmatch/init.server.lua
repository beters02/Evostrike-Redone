local GameOptionsModule = require(script:WaitForChild("GameOptions"))
type GameStatus = "Running" | "Paused" | "Stopped" | "Waiting"
type RoundEndResult = "Condition" | "Timer"
type PlayerData = {
    Player: Player,
    Kills: number,
    Deaths: number,
    Score: number,
    Connections: {},
    States: {GuiTopBar: boolean},
    Round: {Kills: number, Deaths: number},
    Inventory: GameOptionsModule.Inventory,
    GuiContainer: ScreenGui,
}

-- TAGS
-- DestroyOnClose
-- DestroyOnGameEnd
-- DestroyOnPlayerDied_{playerName}
-- DestroyOnPlayerRemoving_{playerName}
-- DestroyOnPlayerSpawning_{playerName}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)
local TagsLib = require(Framework.Module.lib.fc_tags)
local Timer = require(script:WaitForChild("Timer"))
local Tables = require(Framework.Module.lib.fc_tables)
local EvoEconomy = require(Framework.Module.EvoEconomy)
local EvoPlayer = require(Framework.Module.EvoPlayer)
local EvoMaps = require(Framework.Module.EvoMaps)
local GamemodeSpawns = game.ServerStorage.CurrentSpawns
local Maps = require(Framework.Module.EvoMaps)
local BotService = require(Framework.Service.BotService)

local PlayerData = {}
local GameData = {
    Status = "Waiting" :: GameStatus,
    Connections = {PlayerAdded = false, PlayerRemoving = false, PlayerDied = false, TimerFinished = false, BuyMenu = false},
    Variables = {PlayersCanSpawn = false, BotSpawned = false},
    Options = GameOptionsModule.new(),
    CurrentRound = 1,
    RoundStatus = "Stopped" :: GameStatus,
    Timer = false,
    Spawns = GamemodeSpawns:FindFirstChild("Deathmatch") or GamemodeSpawns.Default,
    Events = script:WaitForChild("Events"),
    Guis = script:WaitForChild("Guis")
}

local GamemodeService2 = require(Framework.Service.GamemodeService2)
local RequestSpawnEvent = Framework.Service.GamemodeService2.RequestSpawn
local RequestDeathEvent = Framework.Service.GamemodeService2.RequestDeath
GamemodeService2:SetMenuType("Lobby")
GamemodeService2.CurrentGamemode = "Deathmatch"

function Start()
    for _, v in pairs(Players:GetPlayers()) do
        local pdata = PlayerDataInit(v)
        if pdata then PlayerData[v.Name] = pdata end
    end

    if PlayerGetCount() < GameData.Options.min_players then
        GameData.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
            local pdata = PlayerDataInit(player)
            if pdata then PlayerData[player.Name] = pdata end
        end)
        while PlayerGetCount() < GameData.Options.min_players do
            print('Waiting for players.')
            task.wait(1.5)
        end
    end

    if GameData.Connections.PlayerAdded then GameData.Connections.PlayerAdded:Disconnect() GameData.Connections.PlayerAdded = nil end

    GameData.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        local pdata = PlayerDataInit(player)
        if pdata then PlayerData[player.Name] = pdata end
        GuiTopBar(player)
        GuiBuyMenu(player)
        ReplicatedStorage:WaitForChild("Remotes").SetMainMenuType:FireClient(player, "Lobby")
    end)

    GameData.Connections.PlayerRemoving = false

    GameData.Connections.PlayerDied = Framework.Module.EvoPlayer.Events.PlayerDiedRemote.OnServerEvent:Connect(function(player, killer)
        TagsLib.DestroyTagged("DestroyOnPlayerDied_" .. player.Name)
        if GameData.Status ~= "Stopped" then
            local stop = RoundProcessPlayerDied(player, killer)
            if not stop then
                PlayerDied(player, killer)
            end
        end
    end)

    GameData.Connections.BuyMenu = ReplicatedStorage.Remotes.BuyMenuSelected.OnServerEvent:Connect(function(_bmplayer, action, item, slot)
        if action == "AbilitySelected" then
            PlayerData[_bmplayer.Name].Inventory.Abilities[slot] = item
            if GameData.Options.buy_menu_add_instant then
                AbilityService:AddAbility(_bmplayer, item)
            end
        elseif action == "WeaponSelected" then
            PlayerData[_bmplayer.Name].Inventory.Weapons[slot] = item
            if GameData.Options.buy_menu_add_instant then
                WeaponService:AddWeapon(_bmplayer, item)
            end
        end
    end)

    RequestSpawnEvent.OnServerInvoke = function(player)
        if GameData.Variables.PlayersCanSpawn then
            PlayerData[player.Name].Variables.InGame = true
            GuiPlayerInitialSpawn(player)
            return true
        end
        return false
    end

    RequestDeathEvent.OnServerInvoke = function(player)
        PlayerData[player.Name].Variables.InGame = false
        if player.Character and player.Character.Humanoid then
            player.Character.Humanoid:TakeDamage(1000)
        end
        return true
    end

    GuiAll(GuiTopBar)
    GuiAll(GuiBuyMenu)
    
    GameData.Variables.PlayersCanSpawn = true

    if #Players:GetPlayers() == 1 and not GameData.Variables.BotSpawned then
        --GameData.Variables.BotSpawned = true
        --BotSpawn()
    end

    RoundStart(1)
    print('round started')
end

function Stop()
    GameData.Status = "Stopped"
    ConnectionsLib.DisconnectAllIn(GameData.Connections)
    TagsLib.DestroyTagged("DestroyOnClose")
end

--@summary Called when game ends naturally by condition/timer
function End(result: RoundEndResult, winner: Player?)
    GameData.Status = "Stopped"

    -- generate next map for gui and ended
    local newMapStr = "Kicking players..."
    if GameData.Options.restart_on_end then
        newMapStr = Maps:GetRandomMapInGamemode("Deathmatch", {Maps:GetCurrentMap()})
        newMapStr = newMapStr and newMapStr.Name or "warehouse"
    end

    GuiGameOver(winner or false, ProcessPlayerPostEarnings(), newMapStr)
    GameData.Events.Ended:Fire(GameData.Options.restart_on_end, GameData.Options.end_screen_length, newMapStr)

    task.delay(GameData.Options.end_screen_length, function()
        Stop()
        for _, v in pairs(PlayerData) do
            PlayerRemoving(v.Player)
        end
    end)

    if GameData.Connections.PlayerDied then
        GameData.Connections.PlayerDied:Disconnect()
    end
    WeaponService:ClearAllPlayerInventories()

    task.wait(0.2)

    for _, v in pairs(Players:GetPlayers()) do
        if v.Character then
            pcall(function()AbilityService:GetPlayerAbilityFolder(v):ClearAllChildren()end)
            v.Character.Humanoid:TakeDamage(1000)
        end
    end
end

function ProcessPlayerPostEarnings()
    local top3 = {}
    for _, plrdata in pairs(PlayerData) do
        local inserted = false
        if #top3 < 3 then
            table.insert(top3, plrdata)
            continue
        end
        for ti, tpd in pairs(top3) do
            if not inserted then
                inserted = true
                if plrdata.Kills > tpd.Kills then
                    tpd[ti] = plrdata
                end
            end
        end
    end
    for ti, tv in pairs(top3) do
        top3[tv.Player.Name] = tv
        top3[ti] = nil
    end

    local function isTop3(player)
        for plrname, _ in pairs(top3) do
            if player.Name == plrname then
                return true
            end
        end
        return false
    end

    local plrEarnings = {}
    local sc
    local xp
    for _, plrdata in pairs(PlayerData) do
        if plrdata.Kills > 0 then
            sc = GameData.Options.base_sc_earned
            xp = GameData.Options.base_xp_earned
            if isTop3(plrdata.Player) then
                sc += 10
                xp += 100
            end
            EvoEconomy:Increment(plrdata.Player, "StrafeCoins", sc)
            EvoEconomy:Increment(plrdata.Player, "XP", xp)
            EvoEconomy:Save(plrdata.Player)
            plrEarnings[plrdata.Player.Name] = {sc = sc, xp = xp}
        end
    end
    return plrEarnings
end

--

function RoundStart(round: number)
    assert(GameData.RoundStatus ~= "Running", "Round already started.")
    GameData.RoundStatus = "Running"
    GameData.CurrentRound = round

    for _, v in pairs(PlayerData) do
        --GuiPlayerInitialSpawn(v.Player)
    end

    GameData.Timer = Timer.new(GameData.Options.round_length)
    GameData.Timer:Start()
    GameData.Connections.TimerFinished = GameData.Timer.Finished.Event:Once(function()
        End("Timer")
    end)
end

--[[function RoundEnd(result: RoundEndResult, winner: Player?) Not needed in Deathmatch
    if result ~= "Timer" then
        GameData.Timer:Stop()
    end
end]]

--@summary Processes whether or not the game should end
function RoundProcessPlayerDied(player, killer): boolean
    local succ, result = pcall(function() return PlayerDataIncrement(player, "Deaths", 1) end)
    if not succ then warn(result) else PlayerData[player.Name] = result end
    GuiTopBarUpdateScore(player, false, PlayerDataGetKey(player, "Deaths"))

    if killer and player ~= killer then
        succ, result = pcall(function() return PlayerDataIncrement(killer, "Kills", 1) end)
        if not succ then warn(result) else PlayerData[killer.Name] = result end
        GuiTopBarUpdateScore(killer, PlayerDataGetKey(killer, "Kills"))
        if PlayerDataGetKey(killer, "Kills") >= GameData.Options.score_to_win_game then
            End("Condition", killer)
            return true
        end
    end
    
    return false
end

--

function PlayerSpawn(player)
    if not player:GetAttribute("Loaded") then
        repeat task.wait() until player:GetAttribute("Loaded")
    end
    local pd = PlayerData[player.Name] or PlayerDataGet(player)
    TagsLib.DestroyTagged("DestroyOnPlayerSpawning_"..player.Name)
    player:LoadCharacter()
    task.wait()
    local char = player.Character or player.CharacterAdded:Wait()
    InitSpawnedCharacter(player, pd, char)
end

function BotSpawn()
    local Bot = BotService:AddBot({Respawn = false})
    InitSpawnedCharacter(false, false, Bot.Character)
    Framework.Service.BotService.Remotes.BotDiedBindable.Event:Once(function(bot, botChar)
        task.delay(3, function()
            BotSpawn()
        end)
    end)
end

function InitSpawnedCharacter(player, playerData, char)
    local cf = PlayerGetSpawnPoint()
    char:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 2, 0)
    char:WaitForChild("Humanoid").Health = GameData.Options.starting_health
    EvoPlayer:SetHelmet(char, GameData.Options.starting_helmet)
    EvoPlayer:SetShield(char, GameData.Options.starting_shield or 0)
    EvoPlayer:SetSpawnInvincibility(char, true, GameData.Options.spawn_invincibility)

    if player then
        for _, item in pairs(playerData.Inventory.Weapons) do
            WeaponService:AddWeapon(player, item)
        end
        for _, item in pairs(playerData.Inventory.Abilities) do
            AbilityService:AddAbility(player, item)
        end
    end
end

function PlayerDied(player, killer)
    if PlayerData[player.Name].Variables.InGame then
        GuiPlayerDied(player, killer)
    end
end

function PlayerRemoving(player)
    local playerdata = PlayerDataGet(player)
    if playerdata then
        ConnectionsLib.DisconnectAllIn(PlayerData[player.Name].Connections)
        PlayerData[player.Name] = nil
    end
    TagsLib.DestroyTagged("DestroyOnPlayerDied_" .. player.Name)
    TagsLib.DestroyTagged("DestroyOnPlayerRemoving_" .. player.Name)
end

--

function PlayerGetCount()
    local count = 0
    for _, _ in pairs(PlayerData) do
        count += 1
    end
    return count
end

function PlayerGetSpawnPoint()
    local points = {}
    local lowest
    local spawns

    -- get spawn location in zones based on amount of players in game (disabled temporarily)
    spawns = GameData.Spawns.Zone1:GetChildren()

    for _, v in pairs(Players:GetPlayers()) do
        if not v.Character or v.Character.Humanoid.Health <= 0 then continue end

        for _, spwn in pairs(spawns) do
            if spwn:IsA("Part") then
                if not points[spwn.Name] then points[spwn.Name] = 10000 end
                points[spwn.Name] -= (v.Character:WaitForChild("HumanoidRootPart").CFrame.Position - spwn.CFrame.Position).Magnitude

                if not lowest or points[spwn.Name] < lowest[2] then
                    lowest = {spwn, points[spwn.Name]}
                end
            end
        end
    end

    lowest = lowest and lowest[1] or spawns[math.random(1, #spawns)]
    return lowest.CFrame
end

--

--@summary Returns table if init
function PlayerDataInit(player)
    if not PlayerData[player.Name] then
        local pd = {
            Player = player,
            Kills = 0,
            Deaths = 0,
            Round = {Kills = 0, Deaths = 0},
            Score = 0,
            Inventory = Tables.deepcopy(GameData.Options.inventory),
            Connections = {},
            States = {GuiTopBar = false},
            Variables = {InGame = true}
        } :: PlayerData
        task.spawn(function()
            GuiContainer(player)
        end)
        return pd
    end
    return false
end

function PlayerDataGet(player)
    local pdata = PlayerData[player.Name]
    while not pdata do
        pdata = PlayerData[player.Name]
        task.wait(0.2)
    end
    return PlayerData[player.Name]
end

function PlayerDataGetKey(player, key)
    return PlayerDataGet(player)[key]
end

function PlayerDataIncrement(player, key, amnt)
    local pd = PlayerDataGet(player)
    pd[key] += amnt
    return pd
end

function PlayerDataSetState(player, key, new)
    local pd = PlayerDataGet(player)
    pd.States[key] = new
    return pd
end

--[[function PlayerDataResetRound(player)
    PlayerDataGet(player)
    PlayerData[player.Name].Round = {Kills = 0, Deaths = 0}
end

function PlayerDataSetKey(player, key, new)
    PlayerDataGet(player)
    PlayerData[player.Name][key] = new
    return new
end

function PlayerDataRoundIncrement(player, key, amnt)
    PlayerDataGet(player)
    PlayerData[player.Name].Round[key] += amnt
end]]

--

--@summary Add a gui to a player
function Gui(player: Player, gui: string, resets: boolean?, tags: table?, attributes: table?)
    if not GameData.Guis:FindFirstChild(gui) then return end
    if player.PlayerGui:FindFirstChild(gui) then return end
    local _guiScript = GameData.Guis[gui]:Clone()
    local _gui = _guiScript:WaitForChild("Gui")

    Tables.doIn(tags, function(value)
        CollectionService:AddTag(_gui, value)
        CollectionService:AddTag(_guiScript, value)
    end)

    Tables.doIn(attributes, function(value, index)
        _guiScript:SetAttribute(index, value)
        _gui:SetAttribute(index, value)
    end)

    local pgui = player:WaitForChild("PlayerGui")
    if resets then
        _guiScript.Parent = pgui
    else
        _gui.ResetOnSpawn = false
        _guiScript.Parent = pgui:WaitForChild("GamemodeContainer")
    end
    
    return _guiScript
end

function GuiAll(callback, ...)
    for _, player in pairs(Players:GetPlayers()) do
        callback(player, ...)
    end
end

function GuiPlayerInitialSpawn(player)
    PlayerDataGet(player)
    local gui = Gui(player, "PlayerInitialSpawn", false, {"DestroyOnPlayerSpawning_" .. player.Name, "DestroyOnStop"}, {
        KilledString = "Spawn",
        StartCF = GameData.Options.starting_camera_cframe_map[GamemodeService2.CurrentMap] or GameData.Options.starting_camera_cframe_map.default
    })

    PlayerData[player.Name].Connections.Respawn = gui:WaitForChild("Events"):WaitForChild("RemoteEvent").OnServerEvent:Connect(function(plr, action)
        if plr ~= player then return end
        if action == "Respawn" then
            gui:WaitForChild("Events"):WaitForChild("Finished"):FireClient(player)
            task.wait(0.2)
            PlayerSpawn(plr)
            task.wait()
            PlayerData[plr.Name].Connections.Respawn:Disconnect()
            PlayerData[plr.Name].Connections.Respawn = nil
        end
    end)
end

function GuiPlayerDied(player, killer)
    PlayerDataGet(player)
    local gui = Gui(player, "PlayerDied", false, {"DestroyOnPlayerSpawning_" .. player.Name}, {KillerName = killer and killer.Name or false})
    local killerObject = Instance.new("ObjectValue")
    killerObject.Name = "KillerObject"
    killerObject.Value = killer or nil
    killerObject.Parent = gui

    PlayerData[player.Name].Connections.Respawn = gui:WaitForChild("Events"):WaitForChild("RemoteEvent").OnServerEvent:Connect(function(plr, action)
        if plr ~= player then return end
        if action == "Respawn" then
            gui:WaitForChild("Events"):WaitForChild("Finished"):FireClient(player)
            task.wait(0.2)
            PlayerSpawn(plr)
            task.wait()
            PlayerData[plr.Name].Connections.Respawn:Disconnect()
            PlayerData[plr.Name].Connections.Respawn = nil
        end
    end)
end

function GuiTopBar(player)
    if not PlayerDataGetKey(player, "States")["GuiTopBar"] then
        local _gui = Gui(player, "TopBar", false, {"DestroyOnGameEnd", "DestroyOnPlayerRemoving_" .. player.Name}, {TimerLength = GameData.Timer and GameData.Timer.Time or GameData.Options.round_length})
        local succ, result = pcall(function() return PlayerDataSetState(player, "GuiTopBar", _gui) end)
        if not succ then warn(result) else PlayerData[player.Name] = result end
    end
end

function GuiTopBarUpdateScore(player, kills, deaths)
    local _guiscript = PlayerDataGetKey(player, "States")["GuiTopBar"]
    if _guiscript then
        _guiscript:WaitForChild("Events").RemoteEvent:FireClient(player, "UpdateScoreFrame", kills, deaths)
    end
end

--@summary Add the GamemodeContainer gui to player.
--         GamemodeContainer is a ScreenGui with ResetOnSpawn = false, used for GuiScripts that are meant to not reset.
function GuiContainer(player)
    local pgui = player:WaitForChild("PlayerGui")
    PlayerDataGet(player)
    local container = PlayerData[player.Name].GuiContainer or pgui:FindFirstChild("GamemodeContainer")
    if not container then
        PlayerData[player.Name].GuiContainer = Instance.new("ScreenGui")
        PlayerData[player.Name].GuiContainer.Name = "GamemodeContainer"
        PlayerData[player.Name].GuiContainer.ResetOnSpawn = false
        CollectionService:AddTag(PlayerData[player.Name].GuiContainer, "DestroyOnClose")
        CollectionService:AddTag(PlayerData[player.Name].GuiContainer, "DestroyOnPlayerRemoving_" .. player.Name)
        PlayerData[player.Name].GuiContainer.Parent = pgui
    end
    return PlayerData[player.Name].GuiContainer
end

function GuiBuyMenu(player)
    local pdata = PlayerDataGet(player)
    if not pdata.Connections.BuyMenu then
        pdata.Connections.BuyMenu = true
        local gui = Gui(player, "BuyMenu", false, {"DestroyOnClose", "DestroyOnPlayerRemoving_" .. player.Name})
    end
    PlayerData[player.Name] = pdata
end

function GuiGameOver(winner: Player | false, plrEarnings, newMapStr)
    for _, v in pairs(Players:GetPlayers()) do
        local attributes = {NewMapStr = newMapStr, TimerLength = GameData.Options.end_screen_length}
        local earnings = plrEarnings[v.Name]
        if earnings then
            attributes.EarnedStrafeCoins = earnings.sc
            attributes.EarnedXP = earnings.xp
        end
        Gui(v, "GameOver", false, {"DestroyOnClose"}, attributes)
    end
end

--

local Interface = {
    Stop = Stop,
    PlayerGetCount = PlayerGetCount
}

--@run
Start()
local GameOptionsModule = require(script:WaitForChild("GameOptions"))
local Shared = require(game.ReplicatedStorage.Services.GamemodeService2.GamemodeScripts.Shared)
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
    Inventory: Shared.Inventory,
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

local PlayerData = {}
local GameData = {
    Status = "Waiting" :: GameStatus,
    Connections = {PlayerAdded = false, PlayerRemoving = false, PlayerDied = false, TimerFinished = false, BuyMenu = false},
    Options = GameOptionsModule.new(),
    CurrentRound = 1,
    RoundStatus = "Stopped" :: GameStatus,
    Timer = false,
    Spawns = script:WaitForChild("Spawns"),
    Events = script:WaitForChild("Events"),
    Guis = script:WaitForChild("Guis")
}

function Start()
    print('starting game')
    for _, v in ipairs(Players:GetPlayers()) do
        PlayerDataInit(v)
    end

    if PlayerGetCount() < GameData.Options.min_players then
        GameData.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
            PlayerDataInit(player)
        end)
        while PlayerGetCount() < GameData.Options.min_players do
            print('Waiting for players.')
            task.wait(1.5)
        end
    end

    ConnectionsLib.SmartDisconnect(GameData.Connections.PlayerAdded)
    GameData.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        PlayerDataInit(player)
        GuiTopBar(player)
        GuiBuyMenu(player)
    end)

    GameData.Connections.PlayerRemoving = false

    GameData.Connections.PlayerDied = Framework.Module.EvoPlayer.Events.PlayerDiedRemote.OnServerEvent:Connect(function(player, killer)
        TagsLib.DestroyTagged("DestroyOnPlayerDied_" .. player.Name)
        local stop = RoundProcessPlayerDied(player, killer)
        if not stop then
            PlayerDied(player, killer)
        end
    end)

    GuiAll(GuiTopBar)
    GuiAll(GuiBuyMenu)
    
    RoundStart(1)
    print('round started')
end

function Stop()
    ConnectionsLib.DisconnectAllIn(GameData.Connections)
    TagsLib.DestroyTagged("DestroyOnClose")
end

--@summary Called when game ends naturally by condition/timer
function End(result: RoundEndResult, winner: Player?)
    GuiGameOver(winner or false, ProcessPlayerPostEarnings())
    ConnectionsLib.SmartDisconnect(GameData.Connections.PlayerDied)
    WeaponService:ClearAllPlayerInventories()
    for _, v in pairs(Players:GetPlayers()) do
        if v.Character then
            pcall(function()AbilityService:GetPlayerAbilityFolder(v):ClearAllChildren()end)
            v.Character.Humanoid:TakeDamage(1000)
        end
    end
    
    task.delay(GameData.Options.end_screen_length, function()
        Stop()
        for _, v in pairs(PlayerData) do
            PlayerRemoving(v.Player)
        end
        GameData.Events.Ended:Fire(GameData.Options.restart_on_end)
    end)
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

    RoundSetContent(round)

    for _, v in pairs(PlayerData) do
        PlayerSpawn(v.Player)
    end

    GameData.Timer = Timer.new(GameData.Options.round_length)
    GameData.Timer:Start()
    GameData.Connections.TimerFinished = GameData.Timer.Finished.Event:Once(function()
        End("Timer")
    end)
end

function RoundEnd(result: RoundEndResult, winner: Player?)
    if result ~= "Timer" then
        GameData.Timer:Stop()
    end
end

--@summary Processes whether or not the game should end
function RoundProcessPlayerDied(player, killer): boolean
    PlayerDataIncrement(player, "Deaths", 1)
    GuiTopBarUpdateScore(player, false, PlayerDataGetKey(player, "Deaths"))

    if killer and player ~= killer then
        PlayerDataIncrement(killer, "Kills", 1)
        GuiTopBarUpdateScore(killer, PlayerDataGetKey(killer, "Kills"))
    end

    End("Condition", killer or PlayerGetOther(player))
    return true
end

function RoundSetContent(round: number)
    local inventory = GameData.Options.inventory
    inventory.Abilities.primary = Tables.random(GameData.Options.primary_ability)
    inventory.Abilities.secondary = Tables.random(GameData.Options.secondary_ability)
    if round == 1 then
        inventory.Weapons.primary = false
        inventory.Weapons.secondary = Tables.random(GameData.Options.light_secondary)
        GameData.Options.starting_helmet = false
        GameData.Options.starting_shield = 0
    elseif round == 2 then
        inventory.Weapons.primary = false
        inventory.Weapons.secondary = Tables.random(GameData.Options.secondary)
        GameData.Options.starting_helmet = false
        GameData.Options.starting_shield = 50
    elseif round == 3 then
        inventory.Weapons.primary = Tables.random(GameData.Options.light_primary)
        inventory.Weapons.secondary = Tables.random(GameData.Options.light_secondary)
        GameData.Options.starting_helmet = true
        GameData.Options.starting_shield = 50
    else
        inventory.Weapons.primary = Tables.random(GameData.Options.primary)
        local secondaryTable = math.random(1,2) == 1 and GameData.Options.light_secondary or GameData.Options.secondary
        inventory.Weapons.secondary = Tables.random(secondaryTable)
        GameData.Options.starting_helmet = true
        GameData.Options.starting_shield = 50
    end
end

--

function PlayerSpawn(player)
    if not player:GetAttribute("Loaded") then
        repeat task.wait() until player:GetAttribute("Loaded")
    end

    local pd = PlayerDataGet(player)
    local cf = PlayerGetSpawnPoint()
    TagsLib.DestroyTagged("DestroyOnPlayerSpawning_"..player.Name)
    player:LoadCharacter()
    print('LOADING CHARACTER')
    task.wait()
    --local char = player.Character or player.CharacterAdded:Wait()

    local char = player.Character or player.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 2, 0)
    char:WaitForChild("Humanoid").Health = GameData.Options.starting_health
    EvoPlayer:SetHelmet(char, GameData.Options.starting_helmet)
    EvoPlayer:SetShield(char, GameData.Options.starting_shield or 0)

    for _, item in pairs(pd.Inventory.Weapons) do
        WeaponService:AddWeapon(player, item)
    end
    for _, item in pairs(pd.Inventory.Abilities) do
        AbilityService:AddAbility(player, item)
    end
end

function PlayerDied(player, killer)
    GuiPlayerDied(player, killer)
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

function PlayerGetOther(player)
    for _, plrdata in pairs(PlayerData) do
        if plrdata.Player.Name ~= player.Name then
            return plrdata.Player
        end
    end
end

--

--@summary Returns success boolean. if false, then player was already initted
function PlayerDataInit(player)
    if not PlayerData[player.Name] then
        PlayerData[player.Name] = {
            Player = player,
            Kills = 0,
            Deaths = 0,
            Round = {Kills = 0, Deaths = 0},
            Score = 0,
            Inventory = Tables.clone(GameData.Options.inventory),
            Connections = {},
            States = {GuiTopBar = false}
        } :: PlayerData
        PlayerData[player.Name].GuiContainer = GuiContainer(player)
        
        return PlayerData[player.Name]
    end
    return false
end

function PlayerDataResetRound(player)
    PlayerDataGet(player)
    PlayerData[player.Name].Round = {Kills = 0, Deaths = 0}
end

function PlayerDataGet(player)
    while not PlayerData[player.Name] do
        task.wait(0.2)
    end
    return PlayerData[player.Name]
end

function PlayerDataGetKey(player, key)
    return PlayerDataGet(player)[key]
end

function PlayerDataSetKey(player, key, new)
    PlayerDataGet(player)
    PlayerData[player.Name][key] = new
    return new
end

function PlayerDataSetState(player, key, new)
    PlayerDataGet(player)
    PlayerData[player.Name].States[key] = new
    return new
end

function PlayerDataIncrement(player, key, amnt)
    PlayerDataGet(player)
    PlayerData[player.Name][key] += amnt
end

function PlayerDataRoundIncrement(player, key, amnt)
    PlayerDataGet(player)
    PlayerData[player.Name].Round[key] += amnt
end

--

--@summary Add a gui to a player
function Gui(player: Player, gui: string, resets: boolean?, tags: table?, attributes: table?)
    if not GameData.Guis:FindFirstChild(gui) then return end
    local _guiScript = GameData.Guis[gui]:Clone()
    local _gui = _guiScript:WaitForChild("Gui")

    Tables.doIn(tags, function(value)
        CollectionService:AddTag(_gui, value)
        CollectionService:AddTag(_guiScript, value)
    end)

    Tables.doIn(attributes, function(value, index)
        _guiScript:SetAttribute(index, value)
        _gui:SetAttribute(index, value)
        print(index, value)
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
    for _, player in ipairs(Players:GetPlayers()) do
        callback(player, ...)
    end
end

function GuiPlayerDied(player, killer)
    PlayerDataGet(player)
    local gui = Gui(player, "PlayerDied", false, {"DestroyOnPlayerSpawning_" .. player.Name}, {KillerName = killer and killer.Name or false})
    local killerObject = Instance.new("ObjectValue")
    killerObject.Name = "KillerObject"
    killerObject.Value = killer or nil
    killerObject.Parent = gui

    PlayerData[player.Name].Connections.Respawn = gui:WaitForChild("Events"):WaitForChild("RemoteEvent").OnServerEvent:Connect(function(_, action)
        if action == "Respawn" then
            gui:WaitForChild("Events"):WaitForChild("Finished"):FireClient(player)
            task.wait(0.2)
            PlayerSpawn(player)
            task.wait()
            PlayerData[player.Name].Connections.Respawn:Disconnect()
            PlayerData[player.Name].Connections.Respawn = nil
        end
    end)
end

function GuiTopBar(player)
    if not PlayerDataGetKey(player, "States")["GuiTopBar"] then
        local _gui = Gui(player, "TopBar", false, {"DestroyOnGameEnd", "DestroyOnPlayerRemoving_" .. player.Name}, {TimerLength = GameData.Timer and GameData.Timer.Time or GameData.Options.round_length})
        PlayerDataSetState(player, "GuiTopBar", _gui)
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
        local gui = Gui(player, "BuyMenu", false, {"DestroyOnClose", "DestroyOnPlayerRemoving_" .. player.Name})
        pdata.Connections.BuyMenu = gui:WaitForChild("Events"):WaitForChild("RemoteEvent").OnServerEvent:Connect(function(_, action, item, slot)
            if action == "AbilitySelected" then
                PlayerData[player.Name].Inventory.Abilities[slot] = item
                if GameData.Options.buy_menu_add_instant then
                    AbilityService:AddAbility(player, item)
                end
            elseif action == "WeaponSelected" then
                PlayerData[player.Name].Inventory.Weapons[slot] = item
                if GameData.Options.buy_menu_add_instant then
                    WeaponService:AddWeapon(player, item)
                end
            end
        end)
    end
end

function GuiGameOver(winner: Player | false, plrEarnings)
    local earnings
    for _, v in pairs(Players:GetPlayers()) do
        earnings = plrEarnings[v.Name]
        earnings = earnings and {EarnedStrafeCoins = earnings.sc, EarnedXP = earnings.xp} or {}
        Gui(v, "GameOver", false, {"DestroyOnClose"}, earnings)
    end
end

--

local Interface = {
    Stop = Stop,
    PlayerGetCount = PlayerGetCount
}

--@run
print('starting')
Start()
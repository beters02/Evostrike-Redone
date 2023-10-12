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
-- DestroyOnPlayerDied_{playerName}
-- DestroyOnPlayerRemoving_{playerName}

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
    GameData.Events.Ended:Fire(GameData.Options.restart_on_end)
end

--

function RoundStart(round: number)
    assert(GameData.RoundStatus ~= "Running", "Round already started.")
    GameData.RoundStatus = "Running"
    GameData.CurrentRound = round
    GameData.Timer = Timer.new(GameData.Options.round_length)
    GameData.Timer:Start()
    GameData.Connections.TimerFinished = GameData.Timer.Finished.Event:Once(function()
        End("Timer")
    end)
    for _, v in pairs(PlayerData) do
        PlayerSpawn(v.Player)
    end
end

--[[function RoundEnd(result: RoundEndResult, winner: Player?) Not needed in Deathmatch
    if result ~= "Timer" then
        GameData.Timer:Stop()
    end
end]]

--@summary Processes whether or not the game should end
function RoundProcessPlayerDied(player, killer): boolean
    PlayerDataIncrement(player, "Deaths", 1)

    if killer and player ~= killer then
        PlayerDataIncrement(killer, "Kills", 1)
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

    local pd = PlayerDataGet(player)
    local cf = PlayerGetSpawnPoint()
    player:LoadCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 2, 0)

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
    local gui = Gui(player, "PlayerDied", false, {"DestroyOnPlayerDied_" .. player.Name}, {KillerName = killer and killer.Name or false})
    PlayerData[player.Name].Connections.Respawn = gui:WaitForChild("Events"):WaitForChild("RemoteEvent").OnServerEvent:Connect(function(_, action)
        if action == "Respawn" then
            PlayerSpawn(player)
            PlayerData[player.Name].Connections.Respawn:Disconnect()
            PlayerData[player.Name].Connections.Respawn = nil
        end
    end)
end

function GuiTopBar(player)
    if not PlayerDataGetKey(player, "States")["GuiTopBar"] then
        PlayerDataSetState(player, "GuiTopBar", true)
        Gui(player, "TopBar", false, {"DestroyOnClose", "DestroyOnPlayerRemoving_" .. player.Name}, {TimerLength = GameData.Timer and GameData.Timer.Time or GameData.Options.round_length})
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

--

local Interface = {
    Stop = Stop,
    PlayerGetCount = PlayerGetCount
}

--@run
print('starting')
Start()
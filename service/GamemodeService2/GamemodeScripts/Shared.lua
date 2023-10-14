-- Purpose - Shared Gamemode Script Functions & Types
--[[ REMEMBER TO SET PLAYERDATA TO THE RESULT OF THE PLAYERDATA AND GUI FUNCTION IF SETTING ]]

export type GameStatus = "Running" | "Paused" | "Stopped" | "Waiting"
export type Inventory = {
    Weapons: {primary: InventorySlot, secondary: InventorySlot, ternary: InventorySlot},
    Abilities: {primary: InventorySlot, secondary: InventorySlot}
}
export type InventorySlot = string | false
export type PlayerData = {
    Player: Player,
    Kills: number,
    Deaths: number,
    Score: number,
    Connections: {},
    States: {GuiTopBar: boolean},
    Round: {Kills: number, Deaths: number},
    Inventory: Inventory,
    GuiContainer: ScreenGui,
}
export type GameData = {
    Status: GameStatus,
    Connections: {PlayerAdded: RBXScriptSignal | false, PlayerRemoving: RBXScriptSignal | false, PlayerDied: RBXScriptSignal | false, BuyMenu: RBXScriptSignal | false, BuyMenu: RBXScriptSignal | false},
    Options: any,
    CurrentRound: number,
    RoundStatus: GameStatus,
    Timer: boolean,
    Spawns: Folder,
    Events: Folder,
    Guis: Folder
}

type GamemodePlayerData = {[string]: PlayerData}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = {}
local Framework = require(ReplicatedStorage.Framework)
local Tables = require(Framework.Module.lib.fc_tables)

--[[GAMEMODE SCRIPT PLAYERDATA]]
Shared.PlayerData = {}

--@summary Initialize a Player's PlayerData in the GamemodeScript.
--@param   PlayerData: Gamemode's PlayerData Table
--@param   param: Player
--@return  GamemodePlayerData or false if player was already initted
function Shared.PlayerData.Init(PlayerData: GamemodePlayerData, GameData: GameData, player: Player)
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
        PlayerData[player.Name].GuiContainer = Shared.Gui.Container(PlayerData, player)
        
        return PlayerData
    end
    return false
end

--@summary Get a Player's PlayerData. Awaits
function Shared.PlayerData.Get(PlayerData: GamemodePlayerData, player: Player): PlayerData
    while not PlayerData[player.Name] do
        task.wait(0.2)
    end
    return PlayerData[player.Name]
end

function Shared.PlayerData.GetKey(PlayerData: GamemodePlayerData, player: Player, key: string): any
    return Shared.PlayerData.Get(PlayerData, player)[key]
end

function Shared.PlayerData.ResetRound(PlayerData: GamemodePlayerData, player: Player): GamemodePlayerData
    Shared.PlayerData.Get(PlayerData, player)
    PlayerData[player.Name].Round = {Kills = 0, Deaths = 0}
    return PlayerData
end

function Shared.PlayerData.SetKey(PlayerData: GamemodePlayerData, player: Player, key: string, new: any): GamemodePlayerData
    Shared.PlayerData.Get(PlayerData, player)
    PlayerData[player.Name][key] = new
    return PlayerData
end

function Shared.PlayerData.SetState(PlayerData: GamemodePlayerData, player: Player, key: string, new: any): GamemodePlayerData
    Shared.PlayerData.Get(PlayerData, player)
    PlayerData[player.Name].States[key] = new
    return PlayerData
end

function Shared.PlayerData.Increment(PlayerData: GamemodePlayerData, player: Player, key: string, amnt: number)
    Shared.PlayerData.Get(PlayerData, player)
    PlayerData[player.Name][key] += amnt
    return PlayerData
end

function Shared.PlayerData.RoundIncrement(PlayerData: GamemodePlayerData, player: Player, key: string, amnt: number)
    Shared.PlayerData.Get(PlayerData, player)
    PlayerData[player.Name].Round[key] += amnt
    return PlayerData
end

--[[GUI]]
Shared.Gui = {}

--@summary Add the GamemodeContainer gui to player.
function Shared.Gui.Container(PlayerData: PlayerData, player: Player)
    local pgui = player:WaitForChild("PlayerGui")
    Shared.PlayerData.Get(PlayerData, player)
    local container = PlayerData[player.Name].GuiContainer or pgui:FindFirstChild("GamemodeContainer")
    if not container then
        PlayerData[player.Name].GuiContainer = Instance.new("ScreenGui")
        PlayerData[player.Name].GuiContainer.Name = "GamemodeContainer"
        PlayerData[player.Name].GuiContainer.ResetOnSpawn = false
        CollectionService:AddTag(PlayerData[player.Name].GuiContainer, "DestroyOnClose")
        CollectionService:AddTag(PlayerData[player.Name].GuiContainer, "DestroyOnPlayerRemoving_" .. player.Name)
        PlayerData[player.Name].GuiContainer.Parent = pgui
    end
    return PlayerData
end

return Shared
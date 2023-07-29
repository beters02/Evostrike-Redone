local Gamemode = {
	playerAddedConnection = nil,
    currentGamemode = "",
    currentClass = nil,
}
Gamemode.__index = Gamemode


local Players = game:GetService("Players")
Players.CharacterAutoLoads = false
local GamemodeLoc = game:GetService("ServerScriptService"):WaitForChild("Modules").Gamemode
local DefaultGamemode = "Lobby"

function Gamemode.SetGamemode(gamemode: string)
    local class = GamemodeLoc.Class:FindFirstChild(gamemode)
    if not class then warn("Could not find gamemode " .. gamemode) return end
    if Gamemode.playerAddedConnection then Gamemode.playerAddedConnection:Disconnect() end

    class = setmetatable(require(class), Gamemode)
    Gamemode.currentClass = class
    Gamemode.currentGamemode = gamemode

    class:Start()
end

local function StartPlayerAddedFunction(player)
    local g = DefaultGamemode
    local data = player:GetJoinData()
    data = data and data.TeleportData
    if data and data.RequestedGamemode then
        g = data.RequestedGamemode
    end

    -- disconnect player added connection instantly to avoid gamemode starting twice
    Gamemode.playerAddedConnection:Disconnect()
    Gamemode.playerAddedConnection = nil

    -- start game
    Gamemode.SetGamemode(g)
end

local function Init()
    Gamemode.playerAddedConnection = Players.PlayerAdded:Connect(StartPlayerAddedFunction)
end

Init()

return Gamemode
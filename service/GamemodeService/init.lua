--[[

    This will be the manager for gamemodes for Evostrike.

    Start the Service upon Initilization of any experience,
    Listen for Gamemodes via PlayerJoined PlayerData or MatchmakingService Data

    Will be similar to the last Gamemode Module but more tightly organized, with a better Base Class structure.

    The idea is to remove the need for creating other gamemode class objects that are forced to override every
    single function from the base class, instead opting for a large Singleton Gamemode Class with mostly all
    possible gamemode functionality packed into it.

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Client = script:WaitForChild("Client")
if RunService:IsClient() then
    return require(Client)
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Maps = require(ServerStorage:WaitForChild("Stored"):WaitForChild("MapIDs"))

-- [[ SERVICE CONFIGURATION ]]
local lobby_id = Maps.mapIds.lobby        -- In the Lobby, the Gamemode will always be default_gamemode.
local unstable_id = Maps.mapIds.unstable
local default_gamemode = "Deathmatch"
local studio_gamemode = "1v1"   -- The Gamemode that is automatically set in Studio.
--

local GamemodeClass = require(script:WaitForChild("Gamemode"))
local RemoteEvent = script:WaitForChild("RemoteEvent")
local RemoteFunction = script:WaitForChild("RemoteFunction")
local BindableEvent = script:WaitForChild("BindableEvent")
local EvoMM = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("EvoMMWrapper"))
local Admins = require(ServerStorage:WaitForChild("Stored"):WaitForChild("AdminIDs"))

local GamemodeService = {}
GamemodeService.Status = "Stopped"
GamemodeService.Gamemode = false
GamemodeService.Connections = {}
GamemodeService.RestartConnection = false

--@summary Start GamemodeService.
function GamemodeService:Start()
    if GamemodeService.Status == "Running" or GamemodeService.Status == "Initting" then
        warn("GamemodeService is already running!")
        return
    end

    print("GamemodeService Starting!")
    GamemodeService.Status = "Initting"

    self:ConnectClientRemotes()

    local startingGamemode
    if RunService:IsStudio() then
        startingGamemode = studio_gamemode
    elseif game.PlaceId == lobby_id or game.PlaceId == unstable_id then
        startingGamemode = default_gamemode
    else
        startingGamemode = GamemodeService:AwaitGamemodeDataExtraction()
    end

    GamemodeService.Gamemode = self:SetGamemode(startingGamemode)

    RemoteEvent:FireAllClients("Init")

    print("GamemodeService Started!")
end

--@summary Stop GamemodeService.
function GamemodeService:Stop()
    if GamemodeService.Gamemode then
        GamemodeService.Gamemode:Stop()
    end
end

function GamemodeService:SetGamemode(gamemode: string)
    print("Set Gamemode Request Received.")
    if GamemodeService.RestartConnection then
        GamemodeService.RestartConnection:Disconnect()
        GamemodeService.RestartConnection = false
    end

    local gamemodeClass = GamemodeClass.new(gamemode)
    assert(gamemodeClass, "Could not change gamemode! " .. tostring(gamemode) .. " class not found!")

    print("Gamemode Changing.")

    if GamemodeService.Gamemode then
        GamemodeService.Gamemode:Stop(true)
        GamemodeService.Gamemode = false
    end

    script:SetAttribute("CanDamage", gamemodeClass.GameVariables.can_players_damage or false)
    RemoteEvent:FireAllClients("GamemodeChanged", gamemode)

    GamemodeService.RestartConnection = BindableEvent.Event:Connect(function()
        GamemodeService:SetGamemode(GamemodeService.Gamemode.Name)
    end)

    GamemodeService.Gamemode = gamemodeClass
    GamemodeService.Gamemode:Start()

    gamemodeClass.RestartGamemodeFromService = BindableEvent
    return gamemodeClass
end

--@summary Listen & Wait for the Received Gamemode from a Player's TeleportData
function GamemodeService:AwaitGamemodeDataExtraction()
    local startingGamemode
    GamemodeService.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        if GamemodeService.Status == "Verifying" then return end
        GamemodeService.Status = "Verifying"

        local data = player:GetJoinData()
        local gotGamemode = (data and data.TeleportData) and data.TeleportData.RequestedGamemode or false
        if not gotGamemode then
            data = EvoMM.MatchmakingService:GetUserData(player)
            gotGamemode = data and data.RequestedGamemode
        end

        if not gotGamemode then
            warn("GamemodeService: Player joined with no TeleportData! Starting Default Gamemode.")
            startingGamemode = default_gamemode
        else
            startingGamemode = gotGamemode
        end
        GamemodeService.Connections.PlayerAdded:Disconnect()
    end)
    repeat task.wait() until startingGamemode
    return startingGamemode
end

-- [[ Client -> Server ]]
local clientRemoteFunc = {
    GetCurrentGamemode = function()
        return GamemodeService.Gamemode and GamemodeService.Gamemode.Name or false
    end,
    IsInit = function()
        return GamemodeService.Status ~= "Stopped"
    end,
    ChangeGamemode = function(player, gamemode)
        if Admins:IsAdmin(player) then
            GamemodeService:SetGamemode(gamemode)
            return true
        end
    end,
    GetMenuType = function()
        return (GamemodeService.Gamemode and GamemodeService.Gamemode.GameVariables.main_menu_type) or "Default"
    end,
    AttemptPlayerSpawn = function(player)
        if GamemodeService.Gamemode then
            return GamemodeService.Gamemode:PlayerSpawn(player, GamemodeService.Gamemode.Name == "Deathmatch")
        end
        return false
    end,
    GetPlayerData = function()
        if GamemodeService.Gamemode then
            return GamemodeService.Gamemode.PlayerData
        end
        return false
    end
}

local function _serverInvoke(player, action, ...)
    assert(clientRemoteFunc[action], "ClientRemoteFunction " .. tostring(action) .. " does not exist!")
    return clientRemoteFunc[action](player, ...)
end

--@summary Listen for Client Remotes
function GamemodeService:ConnectClientRemotes()
    RemoteFunction.OnServerInvoke = _serverInvoke
end

return GamemodeService
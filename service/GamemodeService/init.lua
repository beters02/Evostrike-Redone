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

-- [[ SERVICE CONFIGURATION ]]

local lobby_id = 11287185880        -- In the Lobby, the Gamemode will always be default_gamemode.
local default_gamemode = "Deathmatch"

local studio_gamemode = "Range"   -- The Gamemode that is automatically set in Studio.

--

local Types = require(script:WaitForChild("Types"))
local GamemodeClass = require(script:WaitForChild("Gamemode"))
local RemoteEvent = script:WaitForChild("RemoteEvent")
local RemoteFunction = script:WaitForChild("RemoteFunction")
local BindableEvent = script:WaitForChild("BindableEvent")
local EvoMM = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("EvoMMWrapper"))
local Admins = require(game:GetService("ServerStorage"):WaitForChild("Stored"):WaitForChild("AdminIDs"))

local ErrorDef = {Prefix = "GamemodeService: "}
ErrorDef.CouldNotChangeGamemode = ErrorDef.Prefix .. "Could not change gamemode! "

---@interface GamemodeService
local GamemodeService = {}
GamemodeService.Status = "Stopped"
GamemodeService.Gamemode = "None"
GamemodeService.Connections = {}

local Guis = script.Gamemode.Guis

---@function Start GamemodeService.
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
    elseif game.PlaceId == lobby_id then
        startingGamemode = default_gamemode
    else
        startingGamemode = GamemodeService:AwaitGamemodeDataExtraction()
    end

    GamemodeService.Gamemode = self:ChangeMode(startingGamemode, true, true)
    RemoteEvent:FireAllClients("Init")
    print("GamemodeService Started!")
end

---@function Stop GamemodeService.
function GamemodeService:Stop()
    if GamemodeService.Gamemode then
        GamemodeService.Gamemode:Stop()
    end
end

---@function Change the current gamemode.
---@param gamemode string -- The desired gamemode
---@param start boolean? -- Should the game start automatically?
---@param isInitialGamemode boolean? -- Is this the first gamemode set of the server?
---@param bruteForce boolean? -- BruteForce processing variables?
function GamemodeService:ChangeMode(gamemode: string, start: boolean?, isInitialGamemode: boolean?, bruteForce: boolean?): Types.Gamemode
    if start == nil then start = true end
    local currentGamemodeRunning = false

    if type(GamemodeService.Gamemode) ~= "string" then -- GamemodeService.Gamemode = "None" if not initialized.
        if GamemodeService.Gamemode.Name == gamemode and not bruteForce then
            warn(ErrorDef.CouldNotChangeGamemode .. tostring(gamemode) .. " is already the current gamemode!")
            return
        end
        currentGamemodeRunning = true
    end

    local _gamemode = GamemodeClass.new(gamemode)
    if not _gamemode then
        error(ErrorDef.CouldNotChangeGamemode .. tostring(gamemode) .. " class not found!")
    end

    --why the fuck was this in the wrong spot
    if currentGamemodeRunning then
        GamemodeService.Gamemode:Stop(true)
    end
    task.wait(.1)

    GamemodeService.Gamemode = _gamemode
    script:SetAttribute("CanDamage", _gamemode.GameVariables.can_players_damage or false)
    RemoteEvent:FireAllClients("GamemodeChanged", gamemode)
    if start then
        task.delay(0.5, function()
            _gamemode:Start(isInitialGamemode)
        end)
    end
    return _gamemode
end

---@function Restart the current gamemode.
function GamemodeService:RestartMode()
    print("Gamemode Restarting!")
    GamemodeService.Gamemode:Stop()
    GamemodeService:RestartModeGui()
    task.delay(1.5, function()
        RemoteEvent:FireAllClients("GamemodeChanged", GamemodeService.Gamemode.Name)
        GamemodeService.Gamemode = GamemodeClass.new(GamemodeService.Gamemode.Name)
        GamemodeService.Gamemode:Start()
    end)
end

---@function Send the "Restarting Gamemode" GUI to all players.
function GamemodeService:RestartModeGui()
    for _, v in pairs(Players:GetPlayers()) do
        Guis.RestartingGameGui:Clone().Parent = v.PlayerGui
    end
end

---@function Listen & Wait for the Received Gamemode from a Player's TeleportData
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

---@function Listen for Client Remotes
function GamemodeService:ConnectClientRemotes()
    RemoteFunction.OnServerInvoke = function(player, action, ...)
        if action == "GetCurrentGamemode" then
            local gm = GamemodeService.Gamemode
            if gm and type(gm) ~= "string" then gm = gm.Name end
            if not gm then gm = "None" end
            return gm
        elseif action == "IsInit" then
            return GamemodeService.Status ~= "Stopped"
        elseif action == "ChangeGamemode" then
            if Admins:IsAdmin(player) then
                GamemodeService:ChangeMode(..., true)
                return true
            elseif Admins:IsPlaytester(player) then
                if typeof(GamemodeService.Gamemode) == "string" or GamemodeService.Gamemode.Name ~= "Range" then
                    return false
                end
                GamemodeService:ChangeMode(..., true)
                return true
            else return false end
        elseif action == "GetMenuType" then
            return GamemodeService.Gamemode ~= "None" and GamemodeService.Gamemode.GameVariables.main_menu_type or "Default"
        elseif action == "AttemptPlayerSpawn" then
            if type(GamemodeService.Gamemode) ~= "table" or (GamemodeService.Gamemode.Name ~= "Lobby" and GamemodeService.Gamemode.Name ~= "Deathmatch") then print(tostring(GamemodeService.Gamemode)) return false, tostring(GamemodeService.Gamemode) end -- For now, this feature is only enabled on the Lobby.
            GamemodeService.Gamemode:PlayerSpawn(player)
            return true
        elseif action == "GetPlayerData" then
            return type(self.Gamemode) ~= "string" and self.Gamemode.PlayerData
        elseif action == "RestartGamemode" then
            GamemodeService:RestartMode()
            return true
        end
    end
end

---@function Listen for the Server Bindable typically fired by a Gamemode Class
function GamemodeService:ConnectServerBindables()
    GamemodeService.Connections.ServerBindable = BindableEvent.Event:Connect(function(action)
        if action == "GameRestart" then
            print('Restart Received!')
            GamemodeService:RestartMode()
        end
    end)
end

return GamemodeService
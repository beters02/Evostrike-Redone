local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GamemodeService2Loc = Framework.Service.GamemodeService2
local GamemodeService2 = require(GamemodeService2Loc)
local GamemodeService2Bindable = GamemodeService2Loc:WaitForChild("Bindable") :: BindableEvent
local ConnectionsLib = require(Framework.Module.lib.fc_rbxsignals)
local EvoMM = require(Framework.Module.EvoMMWrapper)
local Maps = require(Framework.Module.EvoMaps)
local TagsLib = require(Framework.Module.lib.fc_tags)

local DefaultMap = workspace:GetAttribute("CurrentMap")
local Connections = {Ended = false}
local CurrentGamemodeBaseScript = GamemodeService2:GetGamemodeScript(GamemodeService2.DefaultGamemode)
local CurrentGamemodeScript

--@summary Ran when the first player joins
function Init(player)

    local gmScript = CurrentGamemodeBaseScript
    local teleportData = player:GetJoinData().teleportData
    local mmServiceGameData = EvoMM.MatchmakingService:GetUserData(player)
    local requestedGamemode = (teleportData and teleportData.RequestedGamemode) or (mmServiceGameData and mmServiceGameData.RequestedGamemode) or false

    if requestedGamemode then
        gmScript = GamemodeService2:GetGamemodeScript(teleportData.RequestedGamemode) or gmScript
        print("Player joined with requested gamemode.")
    end

    Start(gmScript)
end

--@summary Ran at the end of Init and on restart
function Start(gmScript)
    if CurrentGamemodeScript then CurrentGamemodeScript:Destroy() CurrentGamemodeScript = false end
    CurrentGamemodeBaseScript = gmScript

    local newScript = gmScript:Clone()
    newScript.Name = "CurrentGamemode"
    newScript.Parent = script
    
    Connections.Ended = newScript:WaitForChild("Events"):WaitForChild("Ended").Event:Once(function(restart: boolean, endScreenLength: number?, map: string?)
        Stop(restart, (endScreenLength or 15)+0.5, map)
    end)

    if CurrentGamemodeBaseScript.Name ~= "1v1" then
        EvoMM:StartQueueService()
    end

    CurrentGamemodeScript = newScript
end

function Stop(restart: boolean?, delayLength: number?, map: string?, newGamemode: string?)
    restart = restart or false
    map = map or DefaultMap
    delayLength = delayLength or 15

    if newGamemode then
        TagsLib.DestroyTagged("DestroyOnClose")
        CurrentGamemodeScript:Destroy()
        CurrentGamemodeBaseScript = GamemodeService2:GetGamemodeScript(newGamemode)
    end

    ConnectionsLib.SmartDisconnect(Connections.Ended)

    if not restart then
        print("KICKING ALL PLAYERS")
        TeleportService:TeleportAsync(Maps.Maps.lobby.ID, Players:GetPlayers())
        Players.PlayerAdded:Once(function(player: Player)
            Init(player)
        end)
        return
    end
    
    print("STARTING NEW GAME IN: " .. tostring(delayLength))
    task.delay(delayLength, function()
        Start(CurrentGamemodeBaseScript)
    end)
    Maps:SetMap(map) -- change map randomly, ignore current map
end

-- [[ SCRIPT RUN ]]
Players.CharacterAutoLoads = false
Players.PlayerAdded:Once(function(player: Player)
    Init(player)
end)

GamemodeService2Bindable.Event:Connect(function(action, ...)
    if action == "Restart" then
        Stop(true, 0.5, ...)
    elseif action == "Set" then
        Stop(true, 1, false, ...)
    end
end)
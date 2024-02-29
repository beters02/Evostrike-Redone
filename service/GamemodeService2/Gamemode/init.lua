-- GamemodeService Gamemode API

-- [[ TYPES ]]
local Types = require(script:WaitForChild("Types"))
local PlayerData = require(script:WaitForChild("PlayerData"))

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--[[ MODULES ]]
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local EvoPlayer = require(Framework.Module.EvoPlayer)
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)

--[[ GAMEMODE MODULES ]]
local GamemodeModules = script:WaitForChild("Modules")
local GamemodeModulesDict = {
    Deathmatch = require(GamemodeModules:WaitForChild("Deathmatch"))
}

-- [[ EVENTS ]]
local PlayerDiedEvent = Framework.Module.EvoPlayer.Events.PlayerDiedBindable

-- [[ GAMEMODE MODULE ]]
local Gamemode = {
    CurrentGamemode = false,

    ModuleConnections = {
        PlayerAdded = Players.PlayerAdded:Connect(function(player)
            modulePlayerAdded(player) -- Add a GamemodeUIContainer to player's PlayerGui
        end)
    },
    
} :: Types.GamemodeModule

--@summary Sets the Currently Selected Gamemode
function Gamemode.Set(gamemode: string)
    local class = GamemodeModulesDict[gamemode]
    if not class then
        error("Could not Set Gamemode to " .. tostring(gamemode) .. " as it does not exist.")
    end

    Gamemode.CurrentGamemode = class
end

--@summary Starts the Currently Selected Gamemode
function Gamemode.Start(GamemodeService)
    local gm = Gamemode.CurrentGamemode
    local cfg = gm.Options
    local playersInGame = Players:GetPlayers()

    -- BindableEvents to call from the GamemodeClass to call a function from this module.
    local bindableStorage = initBindableStorage()
    gm.Bindables = {
        GameEnd = Instance.new("BindableEvent", bindableStorage),
        RoundEnd = Instance.new("BindableEvent", bindableStorage),
        RoundStart = Instance.new("BindableEvent", bindableStorage)
    }

    clearModuleConnections()
    clearGamemodeConnections()

    -- Connect Bindables
    connectModuleEvent("B_GameEnd", gm.Bindables.GameEnd.Event, function()
        Gamemode.Stop()
    end)
    connectModuleEvent("B_RoundEnd", gm.Bindables.RoundEnd.Event, function()
        Gamemode.RoundEnd(gm)
    end)
    connectModuleEvent("B_RoundStart", gm.Bindables.RoundStart.Event, function()
        Gamemode.RoundStart(gm)
    end)

    -- Init Variables
    gm.CurrentRound = 1
    gm.TimeElapsed = 0
    gm.PlayerData = PlayerData.new() :: Types.PlayerDataClass
    gm.Spawns = workspace.Spawns.Deathmatch
    
    -- Init Players
    initPlayers(gm, playersInGame)

    -- call gamemode class Start
    gm.Start(gm)

    -- wait for players
    if #playersInGame < cfg.MIN_PLAYERS then

        connectGamemodeEvent(gm, "PlayerAdded", Players.PlayerAdded, function(player)
            Gamemode.PlayerJoinedWhileWaiting(gm, player)
        end)
        connectGamemodeEvent(gm, "PlayerRemoving", Players.PlayerRemoving, function(player)
            Gamemode.PlayerLeftWhileWaiting(gm, player)
        end)
        
        waitForPlayers()
    end

    disconnectGamemodeEvent(gm, "PlayerAdded")
    disconnectGamemodeEvent(gm, "PlayerRemoving")

    -- connect gamemode actions
    connectGamemodeEvent(gm, "PlayerAdded", Players.PlayerAdded, function(player)
        Gamemode.PlayerJoinedDuringGame(gm, player)
    end)
    connectGamemodeEvent(gm, "PlayerRemoving", Players.PlayerRemoving, function(player)
        Gamemode.PlayerLeftDuringGame(gm, player)
    end)
    connectGamemodeEvent(gm, "PlayerDied", PlayerDiedEvent.Event, function(died, killer)
        Gamemode.PlayerDied(gm, died, killer)
    end)

    -- start the round!
    Gamemode.RoundStart(gm)
    gm.RoundStart(gm)
end

function Gamemode.Stop()
    clearGamemodeConnections()
end

function Gamemode.RoundStart(gm)

    WeaponService:ClearAllPlayerInventories()
    AbilityService:ClearAllPlayerInventories()

    for _, plr in pairs(gm.PlayerData:GetPlayers()) do

        -- load character
        if not plr.Character then
            plr:LoadCharacter()
        end

        -- set health, shield, helmet
        local char = plr.Character or plr.CharacterAdded:Wait()
        char:WaitForChild("Humanoid").Health = gm.Options.START_HEALTH
        if gm.Options.START_SHIELD > 0 then
            EvoPlayer:SetShield(char, gm.Options.START_SHIELD)
        end
        if gm.Options.START_HELMET then
            EvoPlayer:SetHelmet(char, true)
        end

        -- add weapons and abilities
        local plrInv = gm.PlayerData:Get(plr, "inventory")
        for _, weapon in pairs(plrInv.weapon) do
            if not weapon then
                continue
            end
            WeaponService:AddWeapon(plr, weapon)
        end
        for _, ability in pairs(plrInv.ability) do
            if not ability then
                continue
            end
            AbilityService:AddAbility(plr, ability)
        end

        -- gamemode class will handle spawnpoints
        gm:SpawnPlayer(plr)
    end

    gm.TimeElapsed = 0
    gm.Connections.Timer = RunService.Heartbeat:Connect(function(dt)
        gm.TimeElapsed += dt
        if gm.TimeElapsed >= gm.Options.ROUND_LENGTH then
            gm.RoundEnd(gm, "Timer")
            gm.Connections.Timer:Disconnect()
        end
    end)
end

function Gamemode.RoundEnd(gm)
    gm.Connections.Timer:Disconnect()
end

function Gamemode.PlayerJoinedDuringGame(gm, player)
    gm.PlayerData:AddPlayer(player)
    gm.PlayerJoinedDuringGame(gm, player)
end

function Gamemode.PlayerJoinedWhileWaiting(gm, player)
    gm.PlayerData:AddPlayer(player)
    gm.PlayerJoinedWhileWaiting(gm, player)
end

function Gamemode.PlayerLeftWhileWaiting(gm, player)
    gm.PlayerData:RemovePlayer(player)
    gm.PlayerLeftWhileWaiting(gm, player)
end

function Gamemode.PlayerLeftDuringGame(gm, player)
    gm.PlayerData:RemovePlayer(player)
    gm.PlayerLeftDuringGame(gm, player)
end

function Gamemode.PlayerDied(gm, died, killer)
    gm.PlayerData:Increment(died, "deaths", 1)

    if killer == died then
        gm.PlayerKilledSelf(gm, died)
    else
        gm.PlayerData:Increment(killer, "kills", 1)
        gm.PlayerDied(gm, died, killer)
    end
end

--[[ MODULE UTILITY FUNCTIONS ]]

function initPlayers(gm, players)
    for _, player in pairs(players or Players:GetPlayers()) do
        gm.PlayerData:AddPlayer(player)
    end
end

function waitForPlayers(gm)
    repeat task.wait(1) until #gm.PlayerData:GetPlayers() >= gm.Options.MAX_PLAYERS
end

function modulePlayerAdded(player)
    if not EvoPlayer:IsLoaded(player) then
        EvoPlayer:DoWhenLoaded(player, function()
            modulePlayerAdded(player)
        end)
    end

    local GamemodeContainerGui = Instance.new("ScreenGui", player.PlayerGui)
    GamemodeContainerGui.ResetOnSpawn = false
    GamemodeContainerGui.IgnoreGuiInset = true
    GamemodeContainerGui.Name = "GAMEMODESERVICE_GAMEMODE_UI"
end

function initBindableStorage()
    local storage = script:FindFirstChild("GM_Bindables")
    if storage then
        storage:ClearAllChildren()
    else
        storage = Instance.new("Folder", script)
        storage.Name = "GM_Bindables"
    end
    return storage
end

function clearGamemodeConnections()
    for _, conn in pairs(Gamemode.CurrentGamemode.Connections) do
        conn:Disconnect()
    end
    Gamemode.CurrentGamemode.Connections = {}
end

function clearModuleConnections()
    for i, conn in pairs(Gamemode.ModuleConnections) do
        if i == "PlayerAdded" then
            continue
        end
        conn:Disconnect()
    end
end

function connectGamemodeEvent(gm, id, event, callback)
    if gm.Connections[id] then
        gm.Connections[id]:Disconnect()
    end
    gm.Connections[id] = event:Connect(callback)
end

function disconnectGamemodeEvent(gm, id)
    if gm.Connections[id] then
        gm.Connections[id]:Disconnect()
        gm.Connections[id] = nil
    end
end

function connectModuleEvent(id, event, callback)
    if Gamemode.ModuleConnections[id] then
        Gamemode.ModuleConnections[id]:Disconnect()
    end
    Gamemode.ModuleConnections[id] = event:Connect(callback)
end

return Gamemode
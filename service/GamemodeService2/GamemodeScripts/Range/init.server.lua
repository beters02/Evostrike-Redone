local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local BotService = require(Framework.Service.BotService)
local EvoMaps = require(Framework.Module.EvoMaps)
local GamemodeSpawns = game.ServerStorage.Maps[EvoMaps:GetCurrentMap()].Spawns
local Tables = require(Framework.Module.lib.fc_tables)
local CollectionService = game:GetService("CollectionService")
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local TagsLib = require(Framework.Module.lib.fc_tags)
local EvoPlayer = require(Framework.Module.EvoPlayer)
local GameOptionsModule = require(script:WaitForChild("GameOptions"))

local PlayerData = {}
local GameData = {
    Options = GameOptionsModule.new(),
    Spawns = GamemodeSpawns:FindFirstChild("Deathmatch") or GamemodeSpawns.Default,
    Events = script:WaitForChild("Events"),
    Guis = script:WaitForChild("Guis"),
    Bots = script:WaitForChild("Bots")
}

function Start()
    Players.PlayerAdded:Connect(function(player)
        PlayerDataInit(player)
        GuiBuyMenu(player)
        PlayerSpawn(player)
    end)
    for _, v in pairs(Players:GetPlayers()) do
        local succ = PlayerDataInit(v)
        if succ then
            GuiBuyMenu(v)
            PlayerSpawn(v)
        end
    end
    local botprop = {SpawnCFrame = true, StartingShield = 50, StartingHelmet = true}
    for _, v in pairs(GameData.Bots:GetChildren()) do
        botprop.SpawnCFrame = v.PrimaryPart.CFrame
        BotService:AddBot(botprop)
    end
end

function PlayerDataGet(player)
    while not PlayerData[player.Name] do
        task.wait(0.2)
    end
    return PlayerData[player.Name]
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
        }
        PlayerData[player.Name].GuiContainer = GuiContainer(player)
        
        return PlayerData[player.Name]
    end
    return false
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

function PlayerSpawn(player)
    if not player:GetAttribute("Loaded") then
        repeat task.wait() until player:GetAttribute("Loaded")
    end

    local pd = PlayerData[player.Name] or PlayerDataGet(player)
    local cf = PlayerGetSpawnPoint()
    TagsLib.DestroyTagged("DestroyOnPlayerSpawning_"..player.Name)
    player:LoadCharacter()
    task.wait()
    --local char = player.Character or player.CharacterAdded:Wait()

    local char = player.Character or player.CharacterAdded:Wait()
    char:WaitForChild("HumanoidRootPart").CFrame = cf + Vector3.new(0, 2, 0)
    char:WaitForChild("Humanoid").Health = GameData.Options.starting_health
    EvoPlayer:SetHelmet(char, GameData.Options.starting_helmet)
    EvoPlayer:SetShield(char, GameData.Options.starting_shield or 0)
    EvoPlayer:SetSpawnInvincibility(char, true, GameData.Options.spawn_invincibility)

    for _, item in pairs(pd.Inventory.Weapons) do
        WeaponService:AddWeapon(player, item)
    end
    for _, item in pairs(pd.Inventory.Abilities) do
        AbilityService:AddAbility(player, item)
    end
end

function PlayerDied(player, killer)
    PlayerDataGet(player)
    local gui = Gui(player, "PlayerDied", false, {"DestroyOnPlayerSpawning_" .. player.Name}, {KillerName = killer and killer.Name or false})
    local killerObject = Instance.new("ObjectValue")
    killerObject.Name = "KillerObject"
    killerObject.Value = killer or nil
    killerObject.Parent = gui

    task.delay(2, function()
        gui:WaitForChild("Events"):WaitForChild("Finished"):FireClient(player)
        task.wait(0.2)
        PlayerSpawn(player)
    end)
end

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

function GuiBuyMenu(player)
    local pdata = PlayerDataGet(player)
    if not pdata.Connections.BuyMenu then
        pdata.Connections.BuyMenu = true
        local gui = Gui(player, "BuyMenu", false, {"DestroyOnClose", "DestroyOnPlayerRemoving_" .. player.Name})
    end
    PlayerData[player.Name] = pdata
end

Framework.Module.EvoPlayer.Events.PlayerDiedRemote.OnServerEvent:Connect(function(player, killer)
    PlayerDied()
end)

Start()
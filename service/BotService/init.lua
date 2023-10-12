local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

local RagdollRE = Framework.Module.Ragdolls.Remotes.RemoteEvent
local PlayerDiedEvent = Framework.Module.EvoPlayer.Events.PlayerDiedRemote
local BotAddedEvent = Framework.Service.BotService.Remotes.BotAdded
local Types = require(script:WaitForChild("Types"))
local ServerStorage = game:GetService("ServerStorage")
local StarterCharacterTemplate = game:GetService("StarterPlayer").StarterCharacter
local EvoPlayer = require(Framework.Module.EvoPlayer)

local Bots = {}
Bots.Bots = {}
Bots.BotNames = {"Fred", "Dave", "Laney", "George", "Ardiis"}

-- Add a bot to the game
function Bots:AddBot(properties)
    local character = StarterCharacterTemplate:Clone()
    character.Parent = ServerStorage

    if not properties.SpawnCFrame then properties.SpawnCFrame = game.ReplicatedStorage.Services.GamemodeService2.GamemodeScripts.Deathmatch.Spawns.Default.CFrame end
    local botProperties = Types.BotProperties.new(properties)

    -- set bot loaded property
    botProperties.loaded = false

    -- init bot objects
    character.PrimaryPart.CFrame = properties.SpawnCFrame
    local hum = character:WaitForChild("Humanoid")
    hum.BreakJointsOnDeath = false
    hum.Health = properties.StartingHealth or 100
    EvoPlayer:SetShield(character, properties.StartingShield or 0)
    EvoPlayer:SetHelmet(character, properties.StartingHelmet or false)

    -- assign the given name or random bot name
    local botName = properties.Name or self.BotNames[#self.BotNames]
    character.Name = tostring(botName)

    -- init unique bot ID for server identification
    local id = #Bots.Bots + 1

    -- create bot object
    local new_bot: Types.Bot = {
        Name = botName,
        Character = character,
        Humanoid = hum,
        Properties = botProperties,
        ID = id,
        IsBot = true
    }

    new_bot.LoadCharacter = function(tab)
        if new_bot.Properties.Respawn and not new_bot.Properties.Destroyed then
            Bots:RespawnBot(new_bot)
            return
        end
        return false
    end
    
    -- init bot -> player functionality
    new_bot = Types.Bot.new(new_bot)
    Bots.Bots[id] = new_bot

    -- set bot collision
    task.spawn(function()
        for i, v in pairs(character:GetDescendants()) do
            if v:IsA("Part") or v:IsA("MeshPart") then
                if v.Name:match("Foot") then
                    v.CollisionGroup = "PlayerFeet"
                    continue
                end

                v.CollisionGroup = "Bots"
            end
        end
    end)

    -- connect died event
    _connectBotDiedEvent(new_bot)

    -- tag bot
    CollectionService:AddTag(character, "Bot")

    -- move to workspace
    character.Parent = workspace

    -- fire botadded event to all clients
    BotAddedEvent:FireAllClients(character)

    -- create ragdolls
    RagdollRE:FireAllClients("NonPlayerInitRagdoll", character)

    new_bot.Properties.Loaded = true
    return new_bot
end

function Bots:RemoveBot(character, bot)
    pcall(function() (character or bot.Character).Humanoid:SetAttribute("Removing", true) end)
    if not bot then
        local _, err = pcall(function()
            bot = Bots:GetBotFromCharacter(character)
        end)
        if not bot then warn("Could not remove bot " .. tostring(character) .. " could not find bot from character. " .. tostring(err)) return false end
    end
    if bot.Properties._humDiedConn then bot.Properties._humDiedConn:Disconnect() end
    bot.Character:Destroy()
    table.remove(Bots.Bots, bot.ID)
    bot = nil
    return true
end

-- The default Respawn function that is called when a bot is respawned.
function Bots:RespawnBot(_bot)
    _bot.Character:Destroy()
    local char, hum = _createBotCharacter(_bot.Name, _bot.Properties)
    _bot.Character = char
    _bot.Humanoid = hum
    _connectBotDiedEvent(_bot)
    _bot.Character.Parent = workspace
    -- tag bot
    CollectionService:AddTag(char, "Bot")
    -- fire botadded event to all clients
    BotAddedEvent:FireAllClients(char)
    -- create ragdolls
    RagdollRE:FireAllClients("NonPlayerInitRagdoll", char)
end

function Bots:RemoveAllBots()
    local succ, err
    for i, v in pairs(Bots.Bots) do
        succ, err = pcall(function()
            Bots.RemoveBot(false, v)
        end)
        if not succ then warn(err) end
    end
end

function Bots:GetBots()
    return self.Bots
end

function Bots:GetBotFromCharacter(character)
    for i, v in pairs(Bots.Bots) do
        if character == v.Character then return v end
    end
    return false
end

function _createBotCharacter(name, properties)
    -- create bot character
    local character = StarterCharacterTemplate:Clone()
    character.Parent = ServerStorage
    character.PrimaryPart.CFrame = properties.SpawnCFrame
    local hum = character:WaitForChild("Humanoid")
    hum.BreakJointsOnDeath = false
    character.Name = name
    -- set bot collision
    for i, v in pairs(character:GetDescendants()) do
        if v:IsA("Part") or v:IsA("MeshPart") then
            if v.Name:match("Foot") then
                v.CollisionGroup = "PlayerFeet"
                continue
            end

            v.CollisionGroup = "Bots"
        end
    end
    EvoPlayer:SetShield(character, properties.StartingShield or 0)
    EvoPlayer:SetHelmet(character, properties.StartingHelmet or false)
    return character, hum
end

function _connectBotDiedEvent(new_bot)
    local character, hum = new_bot.Character, new_bot.Humanoid
    new_bot.Properties._humDiedConn = hum.Died:Once(function()
        if new_bot.Properties.Destroyed then return end

        -- death event
        PlayerDiedEvent:FireAllClients(character)
        
        if not hum:GetAttribute("Removing") then
            if new_bot.Properties.Respawn then
                if new_bot.Properties.RespawnLength == 0 then -- Manual respawn
                    return
                else
                    task.delay(new_bot.Properties.RespawnLength or 3, function()
                        new_bot:LoadCharacter()
                    end)
                end
            else
                Bots:RemoveBot(new_bot.Character)
            end
        end

        for i, v in pairs(character:GetChildren()) do
            if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
                v.CollisionGroup = "DeadCharacters"
            end
        end
    end)
end

return Bots
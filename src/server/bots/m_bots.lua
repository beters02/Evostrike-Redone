local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.shfc_tables.Location)
local RagdollRE = ReplicatedStorage:WaitForChild("ragdoll"):WaitForChild("remote"):WaitForChild("sharedRagdollRE")
local CollectionService = game:GetService("CollectionService")
local PlayerDiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local BotAddedEvent = ReplicatedStorage:WaitForChild("bots"):WaitForChild("BotAdded")

local bots = {}
local botNames = {"Fred", "Dave", "Laney", "George", "Ardiis"}
local defBotProperties = {Respawn = true, RespawnLength = 3}

export type BotProperties = {
    Respawn: boolean,
    RespawnLength: number? -- Set Respawn Length to 0 for manual respawn
}

export type Bot = {
    Name: string,
    Character: Model,
    Humanoid: Humanoid,
    Properties: table,

    LoadCharacter: (table) -> ()
}

-- Current Alive Map Bots
bots.Bots = {}

-- Names that can be assigned
bots.BotNames = Tables.clone(botNames)

local function initialize()

    -- initialize create on init bots
    local botsFolder = game:GetService("ServerScriptService"):WaitForChild("bots"):WaitForChild("createOnInit")
    for i, v in pairs(botsFolder:GetChildren()) do
        bots.Add(bots, v)
    end

    return bots
end

--

function bots:Add(character, properties, botObj)

    local charcf = false
    if not character then
        character = game:GetService("StarterPlayer").StarterCharacter
        charcf = game.ServerScriptService.gamemode.class.Base.Spawns.Default.CFrame
    end

    -- init properties
    local newProp = Tables.clone(defBotProperties)
    if properties then
        newProp = Tables.combine(newProp, properties) -- must be done in this order for properties to be overwritten correctly
    end

    -- set bot loaded property
    newProp.Loaded = false

    -- create bot
    local _clone = character:Clone()
    if charcf then _clone.PrimaryPart.CFrame = charcf end

    local hum = _clone:WaitForChild("Humanoid")
    hum.BreakJointsOnDeath = false

    -- assign the given name or random bot name
    local botName = (botObj and botObj.Name) or newProp.Name or self.BotNames[#self.BotNames]
    local bni = table.find(self.BotNames, botName)
    if bni then table.remove(self.BotNames, bni) end
    _clone.Name = botName

    -- create bot object
    local new_bot: Bot = botObj or {}
    new_bot.Name = botName
    new_bot.Character = _clone
    new_bot.Humanoid = hum
    new_bot.Properties = newProp

    new_bot.LoadCharacter = function(tab)
        if newProp.Respawn and not newProp.Destroyed then
            self:Add(character, {Name = botName or self.BotNames[math.random(1, #self.BotNames)], new_bot})
        end
        _clone:Destroy()
    end

    new_bot.GetAttribute = function(att)
        return newProp[att]
    end

    new_bot.SetAttribute = function(att, new)
        newProp[att] = new
    end

    new_bot.PlayerGui = {}

    new_bot.Destroy = function()
        newProp.Destroyed = true
        hum:TakeDamage(1000)
        _clone:Destroy()
    end

    -- set bot collision
    task.spawn(function()
        for i, v in pairs(_clone:GetDescendants()) do
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
    hum.Died:Once(function()

        if newProp.Destroyed then return end

        -- death event
        PlayerDiedEvent:FireAllClients(_clone)

        table.insert(self.BotNames, botName)
        
        if not hum:GetAttribute("Removing") then

            if newProp.Respawn then
                if newProp.RespawnLength == 0 then
                    return
                else
                    task.delay(newProp.RespawnLength or 3, function()
                        new_bot:LoadCharacter()
                    end)
                end
            end
        end
        
        bots.Bots[botName] = nil

        for i, v in pairs(_clone:GetChildren()) do
            if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
                v.CollisionGroup = "DeadCharacters"
            end
        end
    end)

    -- tag bot
    CollectionService:AddTag(_clone, "Bot")

    -- move to workspace
    _clone.Parent = workspace

    -- fire botadded event to all clients
    BotAddedEvent:FireAllClients(_clone)

    -- create ragdolls
    RagdollRE:FireAllClients("NonPlayerInitRagdoll", _clone)
    bots.Bots[botName] = new_bot

    new_bot.Properties.Loaded = true

    return new_bot
end

function bots:Remove(character, name)
    
end

function bots:GetBots()
    return self.Bots
end

return initialize()
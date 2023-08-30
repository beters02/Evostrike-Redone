local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.shfc_tables.Location)
local RagdollRE = ReplicatedStorage:WaitForChild("ragdoll"):WaitForChild("remote"):WaitForChild("sharedRagdollRE")
local CollectionService = game:GetService("CollectionService")
local PlayerDiedEvent = ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")

local bots = {}
local botNames = {"Fred", "Dave", "Laney", "George", "Ardiis"}
local defBotProperties = {Respawn = true, RespawnLength = 3}

export type Bot = {
    Name: string,
    Character: Model,
    Humanoid: Humanoid,
    Properties: table
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

function bots:Add(character, properties)

    -- init properties
    local newProp = Tables.clone(defBotProperties)
    if properties then
        newProp = Tables.combine(newProp, properties) -- must be done in this order for properties to be overwritten correctly
    end

    -- create bot
    local _clone = character:Clone()

    local hum = _clone:WaitForChild("Humanoid")
    hum.BreakJointsOnDeath = false

    -- assign the given name or random bot name
    local botName = newProp.Name or self.BotNames[#self.BotNames]
    local bni = table.find(self.BotNames, botName)
    if bni then table.remove(self.BotNames, bni) end
    _clone.Name = botName

    local new_bot: Bot = {Name = botName, Character = _clone, Humanoid = hum, Properties = newProp}

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

        -- death event
        PlayerDiedEvent:FireAllClients(_clone)

        table.insert(self.BotNames, botName)
        
        if not hum:GetAttribute("Removing") then
            task.delay(newProp.RespawnLength or 3, function()
                if newProp.Respawn and _clone then
                    self:Add(character, {Name = botName or self.BotNames[math.random(1, #self.BotNames)]})
                end
                _clone:Destroy()
            end)
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

    -- create ragdolls
    RagdollRE:FireAllClients("NonPlayerInitRagdoll", _clone)
    bots.Bots[botName] = new_bot
end

function bots:Remove(character, name)
    
end

function bots:GetBots()
    return self.Bots
end

return initialize()
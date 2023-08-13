local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.shfc_tables.Location)
local RagdollRE = ReplicatedStorage:WaitForChild("ragdoll"):WaitForChild("remote"):WaitForChild("sharedRagdollRE")

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

    -- assign the given name or random bot name
    local botName = newProp.Name or self.BotNames[#self.BotNames]
    local bni = table.find(self.BotNames, botName)
    if bni then table.remove(self.BotNames, bni) end
    character.Name = botName

    -- create bot
    local hum = character:WaitForChild("Humanoid")
    hum.BreakJointsOnDeath = false
    local new_bot: Bot = {Name = botName, Character = character, Humanoid = hum, Properties = newProp}

    -- create respawn clone if neccessary
    local respawnClone
    if newProp.Respawn then
        respawnClone = character:Clone()
        respawnClone.Parent = ReplicatedStorage:WaitForChild("temp")
    end

    -- connect died event
    hum.Died:Once(function()
        task.delay(newProp.RespawnLength or 3, function()
            if newProp.Respawn then
                self:Add(respawnClone, {Name = botName})
            end
            character:Destroy()
        end)
        
        bots.Bots[botName] = nil
    end)

    -- move to workspace
    character.Parent = workspace

    -- create ragdolls
    RagdollRE:FireAllClients("NonPlayerInitRagdoll", character)
    bots.Bots[botName] = new_bot
end

function bots:Remove(character, name)
    
end

function bots:GetBots()
    return self.Bots
end

return initialize()
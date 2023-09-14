local Types = {}

export type BotProperties = {
    SpawnCFrame: CFrame,
    Respawn: boolean,
    RespawnLength: number?, -- Set Respawn Length to 0 for manual respawn
}

Types.BotProperties = {}
Types.BotProperties.new = function(overwrite: table?)
    local botprop = {Respawn = true, RespawnLength = 3, SpawnCFrame = CFrame.new()} :: BotProperties
    if overwrite then
        for i, v in pairs(overwrite) do
            botprop[i] = v
        end
    end
    return botprop
end

export type Bot = {
    Name: string,
    Character: Model,
    Humanoid: Humanoid,
    Properties: table,
    ID: number,

    LoadCharacter: (table) -> ()
}

Types.Bot = {}
Types.Bot.new = function(botTable: table)
    local _Bot: Bot = {
        Name = botTable.Name,
        Character = botTable.Character,
        Humanoid = botTable.Humanoid,
        Properties = botTable.Properties
    }

    -- LoadCharacter must be done in AddBot
    _Bot.LoadCharacter = botTable.LoadCharacter

    _Bot.GetAttribute = function(tab, att)
        return _Bot.Properties[att]
    end

    _Bot.SetAttribute = function(tab, att, new)
        _Bot.Properties[att] = new
    end

    _Bot.PlayerGui = {}

    return _Bot :: Bot
end

return Types
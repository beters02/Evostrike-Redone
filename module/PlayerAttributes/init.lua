local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = script:WaitForChild("Events")
local RemoteEvent = Events.RemoteEvent
local RemoteFunction = Events.RemoteFunction

local PlayerAttributes = {
    _Stored = {},
    _CharacterStored = {}
}

function PlayerAttributes:GetAttribute(player, attribute)
    if not PlayerAttributes._Stored[player.Name] then
        return
    end
    return PlayerAttributes._Stored[player.Name][attribute]
end

function PlayerAttributes:SetAttributeAsync(player, attribute, value)
    if not PlayerAttributes._Stored[player.Name] then
        PlayerAttributes._Stored[player.Name] = {}
    end
    PlayerAttributes._Stored[player.Name][attribute] = value
end

function PlayerAttributes:SetAttribute(player, attribute, value)
    PlayerAttributes:SetAttributeAsync(player, attribute, value)

    if RunService:IsServer() then
        RemoteEvent:FireAllClients("SetAttribute", player, attribute, value)
    end

    return PlayerAttributes._Stored[player.Name][attribute]
end

-- Character attributes reset when the character dies.
function PlayerAttributes:GetCharacterAttribute(player, attribute)
    if not PlayerAttributes._CharacterStored[player.Name] then
        return
    end
    return PlayerAttributes._CharacterStored[player.Name][attribute]
end

function PlayerAttributes:SetCharacterAttributeAsync(player, attribute, value)
    if not PlayerAttributes._CharacterStored[player.Name] then
        PlayerAttributes._CharacterStored[player.Name] = {}
    end
    PlayerAttributes._CharacterStored[player.Name][attribute] = value
end

function PlayerAttributes:SetCharacterAttribute(player, attribute, value)
    PlayerAttributes:SetCharacterAttributeAsync(player, attribute, value)

    if RunService:IsServer() then
        RemoteEvent:FireAllClients("SetCharacterAttribute", player, attribute, value)
    end

    return PlayerAttributes._CharacterStored[player.Name][attribute]
end

function PlayerAttributes:ResetCharacterAttributes(player)
    PlayerAttributes._CharacterStored[player.Name] = {}
    if RunService:IsServer() then
        RemoteEvent:FireAllClients("ResetCharacterAttributes", player)
    end
end

function PlayerAttributes:GetAttributes(player)
    return PlayerAttributes._Stored[player.Name]
end

function PlayerAttributes:GetCharacterAttributes(player)
    return PlayerAttributes._CharacterStored[player.Name]
end

-- MAIN

Players.PlayerAdded:Connect(function(player)
    PlayerAttributes._Stored[player.Name] = {}
    PlayerAttributes._CharacterStored[player.Name] = {}

    player.CharacterAdded:Connect(function()
        PlayerAttributes._CharacterStored[player.Name] = {}
    end)
end)

if RunService:IsServer() then
    RemoteFunction.OnServerInvoke = function(_, action, ...)
        if action == "InitPlayer" then
            return PlayerAttributes._Stored, PlayerAttributes._CharacterStored
        elseif action ~= "SetAttribute" and action ~= "SetCharacterAttribute" then
            return PlayerAttributes[action](PlayerAttributes, ...)
        end
    end
elseif RunService:IsClient() then
    local Stored, CharacterStored = RemoteFunction:InvokeServer("InitPlayer")
    PlayerAttributes._Stored = Stored
    PlayerAttributes._CharacterStored = CharacterStored

    RemoteEvent.OnClientEvent:Connect(function(action, ...)
        PlayerAttributes[action](PlayerAttributes, ...)
    end)
end

return PlayerAttributes
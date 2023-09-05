local Players = game:GetService("Players")
local BotAdded = game:GetService("ReplicatedStorage"):WaitForChild("bots"):WaitForChild("BotAdded")
local GetBots = game:GetService("ReplicatedStorage"):WaitForChild("bots"):WaitForChild("GetBots")
local Conn = {}

local function createHighlight(character, isEnemy)
    if character:FindFirstChild("EnemyHighlight") then
        character.EnemyHighlight:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Name = "EnemyHighlight"
    highlight.Parent = character
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.3

    if isEnemy then
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(91, 0, 0)
    else
        highlight.FillColor = Color3.fromRGB(158, 212, 233)
        highlight.OutlineColor = Color3.fromRGB(66, 77, 95)
    end

    return highlight
end

local function initPlayersConnections(player)
    if not Conn[player.Name] then
        Conn[player.Name] = player.CharacterAdded:Connect(function(char) createHighlight(char, true) end) -- For now, everyone is an enemy.
    end
end

Players.PlayerAdded:Connect(function(player)
    if player == Players.LocalPlayer then return end
    initPlayersConnections(player)
end)

for _, currplr in pairs(Players:GetPlayers()) do
    initPlayersConnections(currplr)
end

BotAdded.OnClientEvent:Connect(function(botCharacter)
    createHighlight(botCharacter, true)
end)

local Bots = GetBots:InvokeServer()
if Bots then
    for _, currbot in pairs(Bots) do
        createHighlight(currbot, true)
    end
end
local gamemode = require(script.Parent:WaitForChild("m_gamemode"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Gamemode = require(Framework.sm_gamemode.Location)
local SetRemote = ReplicatedStorage:WaitForChild("gamemode"):WaitForChild("remote"):WaitForChild("Set")

local Admins = {"EPIXPLODE", "PetersNolan505", "NolanPeters505", "beters"}
if game:GetService("RunService"):IsStudio() then table.insert(Admins, "Player1") table.insert(Admins, "Player2") end
local verify = function(pstr)
    for i, v in pairs(Admins) do
        if pstr == v then return true end
    end
    return false
end

SetRemote.OnServerEvent:Connect(function(player, gamemodeName)
    if not verify(player.Name) then return end
    Gamemode.SetGamemode(gamemodeName)
end)

gamemode.Init()
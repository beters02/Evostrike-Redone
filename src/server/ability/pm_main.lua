--[[
    AbilityModule utilizes a base AbilityClass to create an ability.
]]

local Ability = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Players = game:GetService("Players")
local Location = Framework.Ability.Location

function Ability.Add(player, abilityName)
    local class = Location.Parent.class:FindFirstChild(abilityName)
    if not class then return end

    -- create abilityFolder
    local folder = Instance.new("Folder")
    folder.Name = "AbilityFolder_" .. abilityName
    folder.Parent = player.Character

    -- create remotes
    local remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = folder
    local are = Instance.new("RemoteEvent")
    are.Name = "AbilityRemoteEvent"
    local arf = Instance.new("RemoteFunction")
    arf.Name = "AbilityRemoteFunction"
    local abe = Instance.new("BindableEvent")
    abe.Name = "AbilityBindableEvent"
    are.Parent, arf.Parent, abe.Parent = remotesFolder, remotesFolder, remotesFolder

    -- create scripts
    local scriptsFolder = Instance.new("Folder")
    scriptsFolder.Name = "Scripts"
    local sc, cc = Location.Parent.obj.base_server:Clone(), Location.Parent.obj.base_client:Clone()
    sc.Parent, cc.Parent = scriptsFolder, scriptsFolder
    scriptsFolder.Parent = folder
    scriptsFolder.base_server.Enabled = true
end

function Ability.ClearPlayerInventory(player)
    for _, v in pairs(player.Character:GetChildren()) do
        if not string.match(v.Name, "AbilityFolder") then continue end
        v:Destroy()
    end
end

function Ability.ClearAllPlayerInventories()
    for _, plr in pairs(Players:GetPlayers()) do
        if not plr.Character then continue end
        task.spawn(function()
            Ability.ClearPlayerInventory(plr)
        end)
    end
end

return Ability
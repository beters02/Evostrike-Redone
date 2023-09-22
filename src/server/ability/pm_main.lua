--[[
    AbilityModule utilizes a base AbilityClass to create an ability.
]]

local Ability = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Players = game:GetService("Players")
local Location = Framework.Ability.Location
local Class = ReplicatedStorage:WaitForChild("ability"):WaitForChild("class")

function Ability.Add(player, abilityName)
    print(player, abilityName)
    local class = Class:FindFirstChild(abilityName)
    print(class)
    if not class then return end

    -- create abilityFolder
    local folder = Instance.new("Folder")
    folder.Name = "AbilityFolder_" .. abilityName

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
    local scriptsFolder = Instance.new("Folder", folder)
    scriptsFolder.Name = "Scripts"
    local sc, cc = Location.Parent.obj.base_server:Clone(), Location.Parent.obj.base_client:Clone()
    sc.Parent, cc.Parent = scriptsFolder, scriptsFolder
    scriptsFolder.Parent = folder

    if abilityName == "Base" then return end

    local classClone = class:Clone()
    classClone.Name = "AbilityModule"
    classClone.Parent = cc

    local baseClass = Class.Base:Clone()
    baseClass.Name = "BaseAbilityModule"
    baseClass.Parent = cc

    local baseGrenadeClass = Class.GrenadeBase:Clone()
    baseGrenadeClass.Parent = classClone
    
    folder.Parent = player.Character or player.CharacterAdded:Wait()
    scriptsFolder:WaitForChild("base_server").Enabled = true

    print('Added class ! ' .. tostring(abilityName))
end

function Ability.ClearPlayerInventory(player)
    for _, v in pairs(player.Character:GetChildren()) do
        if not string.match(v.Name, "AbilityFolder") then continue end
        v:Destroy()
        print('DESTROYING ABILITY')
    end
end

function Ability.ClearAllPlayerInventories()
    for _, plr in pairs(Players:GetPlayers()) do
        if not plr.Character then continue end
        Ability.ClearPlayerInventory(plr)
    end
end

return Ability
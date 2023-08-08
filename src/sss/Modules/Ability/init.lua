--[[
    AbilityModule utilizes a base AbilityClass to create an ability.
]]

local Ability = {}
local Players = game:GetService("Players")
local Location = game:GetService("ServerScriptService").Modules.Ability

function Ability.Add(player, abilityName)
    local class = Location.Class:FindFirstChild(abilityName)
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
    are.Parent, arf.Parent = remotesFolder, remotesFolder

    -- create scripts
    local scriptsFolder = Location.Scripts:Clone()
    scriptsFolder.Parent = folder
    scriptsFolder.AbilityServer.Enabled = true
end

function Ability.AddAbilityController(char)
    local controller = Location.AbilityController:Clone()
    controller.Parent = char
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

game:GetService("Players").PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        Ability.AddAbilityController(char)
    end)
end)

return Ability
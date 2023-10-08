

--[[ Ability Service ]]

--[[ Note:

    Abilities are special in that if they are a grenade, the Caster will be created within the module for all clients.
    Ability Class Modules are all to be required by the client upon Character creation, in the InitAbilities character script.

    For right now,
    There will be NO AbilityController and all client logic will be handeled in the AbilityLocalScript, server logic handeled in AbilityServerScript.
]]

if game:GetService("RunService"):IsClient() then return require(script:WaitForChild("Client")) end
local Players = game:GetService("Players")

local AbilityService = {}
local Assets = script:WaitForChild("Assets")
local Ability = script:WaitForChild("Ability")
local RemoteEvent = script:WaitForChild("Events").RemoteEvent
local RemoteFunction = script:WaitForChild("Events").RemoteFunction
local Replicate = script.Events.Replicate
local Molly = require(Ability:WaitForChild("Molly"))
local LongFlash = require(Ability:WaitForChild("LongFlash"))
local SmokeGrenade = require(Ability:WaitForChild("SmokeGrenade"))
local HEGrenade = require(Ability:WaitForChild("HEGrenade"))
local Satchel = require(Ability:WaitForChild("Satchel"))

AbilityService._Connections = {}
AbilityService._PlayerData = {}

function AbilityService:Start()
    AbilityService._Connections.RemoteEvent = RemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        if action == "AddAbility" then
            -- do some middleware shit
            self:AddAbility(player, ...)
        elseif action == "RemoveAbility" then
            -- do some middleware shit
            self:RemoveAbility(player, ...)
        end
    end)
    AbilityService._Connections.PlayerCreateAbilityFolder = Players.PlayerAdded:Connect(function(player)
        local charAdded
        charAdded = player.CharacterAdded:Connect(function(character)
            if not AbilityService._Connections.PlayerCreateAbilityFolder then
                charAdded:Disconnect()
                return
            end
            AbilityService:CreateAbilityFolder(character)
        end)
    end)
    AbilityService._Connections.Replicate = Replicate.OnServerEvent:Connect(function(player, action, ...)
        if action == "MollyServerExplode" then
            Molly.ServerExplode(...)
        elseif action == "LongFlashServerPop" then
            local pos, canSee = ...
            if canSee then
                LongFlash.AttemptBlindPlayer(player, pos, false)
            end
        elseif action == "GrenadeFire" then
            local abilityName, origin, direction = ...
            for _, v in pairs(Players:GetPlayers()) do
                if v == player then continue end
                Replicate:FireClient(v, action, abilityName, origin, direction, player)
            end
        elseif action == "SmokeGrenadeServerPop" then
            SmokeGrenade.ServerPop(...)
        elseif action == "HEGrenadeServerPop" then
            HEGrenade.ServerPop(...)
        elseif action == "SatchelServerPop" then
            Satchel.ServerPop(player, ...)
        end
    end)
    RemoteFunction.OnServerInvoke = function(_, action, ...)
        if not AbilityService[action] then return end
        return AbilityService[action](...)
    end
end

function AbilityService:CreateAbilityFolder(character)
    local AbilityFolder = Instance.new("Folder", character)
    AbilityFolder.Name = "AbilityFolder"
    local primary, secondary = Instance.new("Folder", AbilityFolder), Instance.new("Folder", AbilityFolder)
    primary.Name, secondary.Name = "primary", "secondary"
end

--

function AbilityService:AddAbility(player: Player, ability: string)
    if not player.Character then return false end

    local abilityModule, isNoFolder = AbilityService:GetAbilityModule(ability)
    if isNoFolder then
        warn("AbilityFolder wasn't created for " .. player.Name)
        AbilityService:CreateAbilityFolder(player.Character)
        abilityModule = AbilityService:GetAbilityModule(ability)
    end

    if not abilityModule then
        warn("AbilityService: Cannot add ability " .. tostring(ability) .. " AbilityModule not found.")
        return false
    end

    -- server inventory management
    local abilitySlot = require(abilityModule).Configuration.inventorySlot
    if AbilityService:GetPlayerInventorySlot(player, abilitySlot) then
        AbilityService:RemoveAbility(player, abilitySlot)
    end

    -- finalize ability folder
    local folder = Instance.new("Folder", player.Character:WaitForChild("AbilityFolder")[abilitySlot])
    folder.Name = ability
    local client, server = Assets.AbilityLocalScript:Clone(), Assets.AbilityServerScript:Clone()
    client.Parent, server.Parent = folder, folder

    local ModuleObject = Instance.new("ObjectValue", folder)
    ModuleObject.Name = "ModuleObject"
    ModuleObject.Value = abilityModule

    -- now the client side of weapon creation should happen via AbilityLocalScript
    return true
end

function AbilityService:RemoveAbility(player: Player, slot: string)
    local abilityFolder = AbilityService:GetPlayerAbilityFolder(player)
    if not abilityFolder then return false end
    local succ, temperr = pcall(function() abilityFolder[slot]:ClearAllChildren() end)
    if not succ then warn("Could not remove ability " .. tostring(temperr)) return false end
    return succ
end

function AbilityService:RemoveAbilityByName(player: Player, ability: string)
    local abilityFolder = AbilityService:GetPlayerAbilityFolder(player)
    if not abilityFolder then return false end
    for i, v in pairs(abilityFolder:GetChildren()) do
        local _c = v:GetChildren()
        if #_c > 0 and string.lower(_c[1].Name) == string.lower(ability) then
            abilityFolder[i]:Destroy()
            return true
        end
    end
    return false
end

--

function AbilityService:GetAbilityModule(ability: string)
    local module = false
    for _, v in pairs(Ability:GetChildren()) do
        if string.lower(ability) == string.lower(v.Name) then
            module = v
            break
        end
    end
    return module
end

function AbilityService:GetPlayerInventorySlot(player, slot)
    local abilityFolder = AbilityService:GetPlayerAbilityFolder(player)
    if not abilityFolder then return false, "noFolder" end

    local children = abilityFolder[slot]:GetChildren()
    return #children > 0 and children[1] or false
end

function AbilityService:GetPlayerAbilityFolder(player)
    return player.Character and player.Character:FindFirstChild("AbilityFolder") or false
end

return AbilityService
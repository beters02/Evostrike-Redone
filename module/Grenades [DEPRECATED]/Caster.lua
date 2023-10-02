-- [[ Purpose: Caster Container Module for storing casters and caster funtions ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local FastCast = require(Framework.Module.lib.c_fastcast)
local Remotes = script.Parent:WaitForChild("Remotes")

local Caster = {}
Caster._LocalStoredCaster = false
Caster._ReplicateStoredCasters = {} -- other player's casters for replication.
Caster._StoredCastBehaviors = {}

-- [[ Create's a caster for the player if they do not already have one. ]]
function Caster:CreateCaster(player)
    if not Caster._LocalStoredCaster then
        Caster._LocalStoredCaster = FastCast.new()
        Remotes.RemoteEvent:FireServer("CreateCaster")
    else
        Caster._DisconnectCaster()
    end
    return Caster._LocalStoredCaster
end

-- [[ Gets the Player's stored caster. Create's one if it does not exist. Will also return any cast behaviors. ]]
function Caster:GetCaster(player, dontCreate)
    local caster = Caster._LocalStoredCaster or (dontCreate and false) or "create"
    if caster == "create" then
        return Caster:CreateCaster(player)
    end
    return caster
end

-- [[ Creates a new CastBehavior for a grenade, if there has not already been one created (for the grenade) ]]
function Caster:CreateCastBehavior(player, abilityOptions, abilityObjects)
    if Caster._StoredCastBehaviors[abilityObjects.name] then return Caster._StoredCastBehaviors[abilityObjects.name] end
    local casbeh = FastCast.newBehavior()
    casbeh.RaycastParams = RaycastParams.new()
    casbeh.RaycastParams.CollisionGroup = "Bullets"
    casbeh.RaycastParams.FilterDescendantsInstances = {workspace.CurrentCamera, player.Character}
    casbeh.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    casbeh.MaxDistance = 500
    casbeh.Acceleration = Vector3.new(0, -workspace.Gravity * abilityOptions.gravityModifier, 0)
    casbeh.CosmeticBulletContainer = workspace.Temp
    casbeh.CosmeticBulletTemplate = abilityObjects.Models.Grenade
    Caster._StoredCastBehaviors[abilityObjects.name] = casbeh
    Remotes.RemoteEvent:FireServer("CreateCastBehavior", abilityOptions, abilityObjects)
    return casbeh
end

-- [[ Gets the CastBehavior from stored. Creates one if it is non existent. ]]
function Caster:GetCastBehavior(player, abilityOptions, abilityObjects)
    return Caster:CreateCastBehavior(player, abilityOptions, abilityObjects)
end

function Caster:GetCastBehaviors()
    return Caster._StoredCastBehaviors
end

function Caster:FireCaster(behaviorId, origin, direction, speed) -- behaviorId = abilityName
    local caster = Caster:CreateCaster(Players.LocalPlayer)
    local beh = Caster._StoredCastBehaviors[behaviorId]
    if not beh then error("No behavior found fuck") end
    return caster:Fire(origin, direction, speed, beh)
end

function Caster:SetCasterRayHit(player, rayhit, grenade, casterPlayer)
    local caster = Caster:GetCaster(player, true)
    if not caster then warn("Cannot set ray hit, couldn't find caster") return false end

    Caster._DisconnectCaster(player)
    Caster._LocalConnections = {
        rayhit = caster.RayHit:Connect(function(...)
            rayhit(grenade, casterPlayer, ...)
        end),
        lengthchanged = caster.LengthChanged:Connect(function(cast, lastPoint, direction, length, velocity, bullet)
            if bullet then
                local bulletLength = bullet.Size.Z/2
                local offset = CFrame.new(0, 0, -(length - bulletLength))
                bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
            end
        end),
        terminating = caster.CastTerminating:Connect(function()end)
    }
end

function Caster:Remove(player)
    Caster._DisconnectCaster(player)
    Remotes.RemoteEvent:FireServer("RemoveCaster", player.Name)
    Caster._LocalStoredCaster = nil
    return
end

function Caster._DisconnectCaster(player)
    local caster = Caster:GetCaster(player, true)
    if not caster then warn("CANT FIND CASTER") return false end
    if caster._LocalConnections then
        for i, v in pairs(caster._LocalConnections) do
            v:Disconnect()
        end
        caster._LocalConnections = nil
    end
end

-- ** [[ BACKEND REPLICATION FUNCTIONALITY ]] **

local otherPlayers = {}

function otherPlayers.CreateCaster(player, playerBehaviors)
    if not Caster._ReplicateStoredCasters[player.Name] then
        Caster._ReplicateStoredCasters[player.Name] = otherPlayers.CreateCaster(player)
        if playerBehaviors and type(playerBehaviors) == "table" then
            for bi, beh in pairs(playerBehaviors) do
                if not Caster._StoredCastBehavior[bi] then
                    Caster._StoredCastBehavior[bi] = beh
                end
            end
        end
    end
end

function otherPlayers.FireCaster(player, behaviorId, origin, direction, speed)
    local caster = otherPlayers.CreateCaster(player) -- create a caster if we dont have one for the player already
    local beh = Caster._StoredCastBehaviors[behaviorId]
    if not beh then error("No behavior found fuck") end
    caster:Fire(origin, direction, speed, beh)
end

function otherPlayers.CreateCastBehavior(player, abilityOptions, abilityObjects)
    if Caster._StoredCastBehaviors[abilityObjects.name] then return Caster._StoredCastBehaviors[abilityObjects.name] end
    local casbeh = FastCast.newBehavior()
    casbeh.RaycastParams = RaycastParams.new()
    casbeh.RaycastParams.CollisionGroup = "Bullets"
    casbeh.RaycastParams.FilterDescendantsInstances = {workspace.CurrentCamera, player.Character}
    casbeh.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    casbeh.MaxDistance = 500
    casbeh.Acceleration = Vector3.new(0, -workspace.Gravity * abilityOptions.gravityModifier, 0)
    casbeh.CosmeticBulletContainer = workspace.Temp
    casbeh.CosmeticBulletTemplate = abilityObjects.Models.Grenade
    Caster._StoredCastBehaviors[abilityObjects.name] = casbeh
    return casbeh
end

function otherPlayers.RemoveCaster(player)
    if Caster._ReplicatedStoredCasters[player.Name] then
        Caster._ReplicatedStoredCasters[player.Name]:Destroy()
    end
end

-- ** [[ INIT MODULE SCRIPT ]] **

-- [[ Init Caster Remote Functionality for Replication ]]
Remotes.RemoteFunction.OnClientInvoke = function(action, ...)
    if action == "GetCaster" then
        return Caster:GetCaster(Players.LocalPlayer, true)
    end
end

Remotes.RemoteEvent.OnClientEvent:Connect(function(action, ...)
    if action == "CreateCaster" then
        local player = ...
        if Players.LocalPlayer == player then return end
        otherPlayers.CreateCaster(...)
    elseif action == "CreateCastBehavior" then
        local player = ...
        if Players.LocalPlayer == player then return end
        otherPlayers.CreateCastBehavior(...)
    elseif action == "FireCaster" then
        otherPlayers.FireCaster(...)
    elseif action == "RemoveCaster" then
        if Players.LocalPlayer == ... then return end
        otherPlayers.RemoveCaster(...)
    end
end)

--[[ Create any casters for players that already have casters created ]]
task.spawn(function()
    for i, v in pairs(Players:GetPlayers()) do
        if v == Players.LocalPlayer then continue end
        local playerCaster, playerBehaviors = Remotes.RemoteFunction:InvokeServer("GetCaster", v)
        if playerCaster then
            otherPlayers.CreateCaster(v, playerBehaviors)
        end
    end
end)

return Caster
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local AbilityService = Framework.Service.AbilityService
local Ability = require(AbilityService:WaitForChild("Ability"))
local FastCast = require(Framework.Module.lib.c_fastcast)
local Conns = require(Framework.Module.lib.fc_rbxsignals)

local player = Players.LocalPlayer

local PlayerData = {}
local GrenadeAbilityModules = {}
local StoredAbilityClasses = {}
local AbilityRequiredModules = {}
for _, module in pairs(AbilityService.Ability:GetChildren()) do
    local _name = string.lower(module.Name)
    AbilityRequiredModules[_name] = require(module)
    if AbilityRequiredModules[_name].Options and AbilityRequiredModules[_name].Options.isGrenade then
        GrenadeAbilityModules[_name] = module
    end
end

local function InitPlayer(iplayer)
    if not PlayerData[iplayer.Name] then
        PlayerData[iplayer.Name] = {
            Conn = iplayer.CharacterAdded:Connect(function()
                InitCharacter(iplayer)
            end)
        }
        if iplayer.Character then
            InitCharacter(iplayer)
        end
    end
end

local function RemovePlayer(iplayer)
    if PlayerData[iplayer.Name] then
        Conns.DisconnectAllIn(PlayerData[iplayer.Name])
    end
    PlayerData[iplayer.Name] = nil
    RemoveCharacter(iplayer)
end

function InitCaster(_Ability, module)
    local caster = FastCast.new()
    caster.SimulateBeforePhysics = true
    local castBeh = FastCast.newBehavior()

    castBeh.Acceleration = Vector3.new(0, -workspace.Gravity * _Ability.Options.gravityModifier, 0)
    castBeh.AutoIgnoreContainer = false
    castBeh.CosmeticBulletContainer = workspace.Temp
    castBeh.CosmeticBulletTemplate = module:WaitForChild("Assets").Models.Grenade
    caster.RayHit:Connect(function(...)
        _Ability:RayHitCore(...)
    end)
    caster.LengthChanged:Connect(function(...)
        _Ability:LengthChanged(...)
    end)
    caster.CastTerminating:Connect(function(...)
        _Ability.CastTerminating(...)
    end)

    _Ability.Caster = caster
    _Ability.CastBehavior = castBeh
end

function InitCharacter(cplayer)
    RemoveCharacter(cplayer)
    StoredAbilityClasses[cplayer.Name] = {}
    for name, v in pairs(GrenadeAbilityModules) do
        StoredAbilityClasses[cplayer.Name][string.lower(name)] = Ability.new(cplayer, v, true)
        InitCaster(StoredAbilityClasses[cplayer.Name][string.lower(name)], v)
    end
end

function RemoveCharacter(cplayer)
    if StoredAbilityClasses[cplayer.Name] then
        StoredAbilityClasses[cplayer.Name] = nil
    end
end

Framework.Module.EvoPlayer.Events.PlayerDiedBindable.Event:Connect(function()
    RemoveCharacter(player.Character or player)
end)

Framework.Module.EvoPlayer.Events.PlayerDiedRemote.OnClientEvent:Connect(function(died)
    if died == player then return end
    RemoveCharacter(died.Character or died)
end)

AbilityService.Events.RemoteFunction.OnClientInvoke = function(action, ...)
    if action == "LongFlashCanSee" then
        local part = ...
        return AbilityRequiredModules.longflash.CanSee(part)
    end
end

AbilityService.Events.RemoteEvent.OnClientEvent:Connect(function(action, ...)
    if action == "GrenadeFire" then
        local args = table.pack(...)
        local ability, owner = args[1], args[2]
        table.remove(args, 1)
        table.remove(args, 1)
        local success, result = pcall(function()
            StoredAbilityClasses[owner.Name][string.lower(ability)]:FireGrenade(table.unpack(args))
        end)
        if not success then
            warn("Did not replicate Grenade Fire. " .. tostring(result))
        end
    end
end)

InitPlayer(player)
for _, plr in pairs(Players:GetPlayers()) do
    InitPlayer(plr)
end
Players.PlayerAdded:Connect(InitPlayer)
Players.PlayerRemoving:Connect(RemovePlayer)
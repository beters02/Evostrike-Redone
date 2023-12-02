local RunService = game:GetService("RunService")
local AbilityService = game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("AbilityService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.Module.Sound)
local Tables = require(Framework.Module.lib.fc_tables)

local Ability = {
    Options = {
        name = "Ability",
        inventorySlot = "primary",
        isGrenade = false,
        uses = 100,
        cooldown = 4
    }
}
Ability.__index = Ability

function Ability.new(player, module, base) -- base = Replicated Caster
    local req
    req = setmetatable(Tables.clone(require(module)), Ability)
    req.new = nil
    req.Module = module
    req.Player = player
    req.Animations = {}
    req.Connections = {}

    if not base then
        if req.Module:WaitForChild("Assets"):FindFirstChild("Animations") then
            if RunService:IsClient() then
                for _, v in pairs(req.Module.Assets.Animations:GetChildren()) do
                    if string.match(v.Name, "Server") then
                        req.Animations[string.lower(v.Name)] = req.Player.Character:WaitForChild("Humanoid"):WaitForChild("Animator"):LoadAnimation(v)
                    else
                        req.Animations[string.lower(v.Name)] = workspace.CurrentCamera:WaitForChild("viewModel"):WaitForChild("AnimationController"):LoadAnimation(v)
                    end
                end
            end
        end
    end
    
    if req.Options.isGrenade then
        for i, v in pairs(require(AbilityService:WaitForChild("Ability"):WaitForChild("Grenade"))) do
            if i == "Use" or not req[i] then
                req[i] = v
            end
        end
        req.Params = req:GetRaycastParams()
    end
    return req
end

--@summary Called before Use
function Ability:UseCore()
    game.Players.LocalPlayer.PlayerScripts.HUD.UseAbility:Fire(self.Options.inventorySlot)
    self:Use()
end

--@summary The preferred way to play an ability sound
--@param sound Sound | string -- The Sound or it's Name
--@param isReplicated boolean -- Should the sound be replicated?
function Ability:PlaySound(sound: Sound | Folder | string, whereFrom: Instance, isReplicated: boolean?)
    local func = isReplicated and PlayReplicatedSoundFromSound or PlaySoundFromSound

    if type(sound) == "string" then
        sound = self.Assets.Sounds:FindFirstChild(sound)
        if sound then
            func(sound, whereFrom)
        end
        return
    end

    if sound:IsA("Sound") then
        func(sound, whereFrom)
        return
    end

    for _, soundchild in pairs(sound:GetChildren()) do
        if soundchild:IsA("Sound") then
            func(soundchild, whereFrom)
        end
    end
end

--@summary Replicated PlaySound -- PlaySound(sound, true) shorthand
function Ability:PlayReplicatedSound(sound: Sound | Folder | string, whereFrom: Instance)
    self:PlaySound(sound, whereFrom, true)
end

--@summary Play a sound quickly directly from the Sound
function PlaySoundFromSound(sound: Sound, whereFrom)
    Sound.PlayClone(sound, whereFrom)
end

--@summary Play a sound quickly directly from the Sound
function PlayReplicatedSoundFromSound(sound: Sound, whereFrom)
    Sound.PlayReplicatedClone(sound, whereFrom, true)
end

return Ability
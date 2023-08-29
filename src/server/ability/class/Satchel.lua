local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Framework = require(ReplicatedStorage.Framework)
local Sound = require(Framework.shm_sound.Location)
local States = require(Framework.shm_states.Location)

local Satchel = {

    -- grenade settings
    isGrenade = true,
    grenadeThrowDelay = 0.2,
    usingDelay = 1, -- Time that player will be "using" their ability, won't be able to interact with weapons during this time
    acceleration = 10,
    speed = 150,
    gravityModifier = 0.5,
    startHeight = 2,

    -- genral settings
    cooldownLength = 3,
    uses = 100,

    -- satchel settings
    timeBeforeSatchelExplodes = 2.5,
    explosionMaxDamage = 70,
    explosionMaxRadius = 7,

    -- data settings
    abilityName = "Satchel",
    inventorySlot = "primary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
    remoteEvent = nil,

}

function Satchel:Use()

    -- set state var
    States.SetStateVariable("PlayerActions", "grenadeThrowing", self.abilityName)
    task.delay(self.usingDelay, function()
        States.SetStateVariable("PlayerActions", "grenadeThrowing", false)
    end)

    -- play equip sound
    Sound.PlayReplicatedClone(self._sounds.Equip, self.player.Character.PrimaryPart)

    -- initialize Satchel Blast Input
    local inputConn
    inputConn = self.bindableEvent.Event:Connect(function(action)
        print('EVENT CONNECTED')
        print(action)
        if action == "ConnectSatchel" then
            self:ConnectBlast()
            inputConn:Disconnect()
        end
    end)

    -- make player hold grenade in left hand
    workspace.CurrentCamera.viewModel.LeftEquipped:ClearAllChildren()
    local grenadeClone = self.abilityObjects.Models.Grenade:Clone()
    grenadeClone.Parent = workspace.CurrentCamera.viewModel.LeftEquipped
    grenadeClone.Size *= 0.8

    local leftHand = workspace.CurrentCamera.viewModel.LeftHand
    local m6 = leftHand:FindFirstChild("LeftGrip")
    if m6 then m6:Destroy() end

    m6 = Instance.new("Motor6D", leftHand)
    m6.Name = "LeftGrip"
    m6.Part0 = leftHand
    m6.Part1 = grenadeClone
    m6.C0 = CFrame.Angles(0,math.rad(80),0)

    -- play throw animation
    self._animations.throw:Play()
    task.wait(self.grenadeThrowDelay or 0.01)

    -- play throw sound
    Sound.PlayReplicatedClone(self._sounds.Throw, self.player.Character.PrimaryPart)

    -- long flash does CanUse on the server via remoteFunction: ThrowGrenade
    local hit = self.player:GetMouse().Hit
    local used = self.remoteFunction:InvokeServer("ThrowGrenade", hit)

    -- destroy left hand clone once grenade is thrown
    grenadeClone:Destroy()
    m6:Destroy()

    -- update client uses
    if used then
        self.uses -= 1
    end
end

function Satchel:Blast()
    local grenade = ReplicatedStorage.ability.remote.localAbilityBF:Invoke("GetStored", "Satchel")
    grenade = grenade[3]

    local _p = RaycastParams.new()
    _p.FilterType = Enum.RaycastFilterType.Exclude
    _p.FilterDescendantsInstances = {grenade}
    local ray = workspace:Raycast(grenade.CFrame.Position, (self.player.Character.HumanoidRootPart.CFrame.Position - grenade.CFrame.Position).Unit * 100, _p)

    print(ray.Instance:FindFirstAncestorOfClass("Model"))
    if ray.Instance:FindFirstAncestorOfClass("Model") == self.player.Character then
        self.player.Character.HumanoidRootPart:ApplyImpulse((self.player.Character.HumanoidRootPart.CFrame.Position - grenade.CFrame.Position).Unit * ray.Distance * 100)
    end
    print(ray)

    grenade:Destroy()
end

function Satchel:ConnectBlast()
    if self.satchelConnection then self.satchelConnection:Disconnect() end

    local _t = tick() + self.timeBeforeSatchelExplodes
    local debounce = false
    self.satchelConnection = RunService.RenderStepped:Connect(function()
        if debounce then return end
        if UserInputService:IsKeyDown(Enum.KeyCode[self.key]) or tick() >= _t then
            debounce = true
            self:Blast()
            self.satchelConnection:Disconnect()
        end
    end)

    task.delay(5, function() if self.satchelConnection then self.satchelConnection:Disconnect() end end)
end

return Satchel
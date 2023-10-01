local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)
local BotService = require(game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("BotService"))

local Animations = {
    minimumPlayers = 1,
    maximumPlayers = 8,
    startWithBarriers = false,
    playerDataEnabled = false,
    botsEnabled = true,
    queueServiceEnabled = false,
    respawnsEnabled = true,
    respawnLength = 2,
    startWithMenuOpen = false,

    shieldEnabled = true,
    startingShield = 50,
    startingHelmet = true,
    startingHealth = 100,

    maps = {}, -- (init in m_gamemode) {mapName = mapID}

    status = "running",
    isWaiting = false,
    customDiedCallbacks = {}
}

-- Base Functions

-- Init Buy Menu & moduleLocation
function Animations._init(self)
    self.objects.moduleLocation = Animations.objects.baseLocation.Parent.Animations
    self._buyMenuGui = self.objects.moduleLocation.BuyMenu
    return self
end

function Animations:Start()
    print("Gamemode " .. self.Name .. " started! Correct Motherfucker.")

    self:ClearPlayerData()

    -- test wait for everything to load, then init any un-init players
    task.delay(0.5, function()
        for _, player in pairs(Players:GetPlayers()) do
            if not self.playerdata[player.Name] then
                self:InitPlayerData(player)
            end
            if not player.Character then
                self:SpawnPlayer(player)
            end
        end
    end)

    -- init player added connection
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:InitPlayerData(player)
        self:SpawnPlayer(player)
    end)

    -- add bots
    for i, v in pairs(self.objects.bots:GetChildren()) do
        BotService:AddBot({SpawnCFrame = v.PrimaryPart.CFrame, StartingHealth = self.startingHealth, StartingShield = self.shieldEnabled and self.startingShield or 0, StartingHelmet = self.startingHelmet or false})
    end

    -- clear temp
    workspace:WaitForChild("Temp"):ClearAllChildren()

end

function Animations:Stop()

    -- set status
    self.status = "dead"

    -- disconnect connections
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end

    -- remove all weapons and abilities
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()

    -- unload all characters
    for i, v in pairs(Players:GetPlayers()) do
        if v.Character and v.Character.Humanoid then
            v.Character.Humanoid:TakeDamage(1000)
        end
        
        v.Character = nil
    end

    -- clear temps (destroy grenades, bullets, etc)
    workspace.Temp:ClearAllChildren()

    -- destroy bots
    BotService:RemoveAllBots()

    -- clear playerdata instances
    self:ClearPlayerData()

    task.wait(0.1)

    print('Gamemode Lobby Stopped')
end

-- Player Functions

function Animations:InitPlayerData(player)
    if self.playerdata[player.Name] then
        self:ClearPlayerData()
    end

    self.playerdata[player.Name] = {deathCameraScript = false, isSpawned = false, connections = {}, loadout = {weapon = {primary = "AK103", secondary = "Glock17"}, ability = {primary = "Dash", secondary = "Molly"}}}
end

function Animations:SpawnPlayer(player)
    if not player:GetAttribute("Loaded") then
        repeat task.wait() until player:GetAttribute("Loaded")
    end

    player:LoadCharacter()
    task.wait()
    
    local hum = player.Character:WaitForChild("Humanoid")
    player.Character.Humanoid.Health = self.startingHealth

    -- teleport player to spawn
    local spawnLoc = self.objects.spawns.Default
    player.Character.PrimaryPart.Anchored = true
    player.Character:SetPrimaryPartCFrame(CFrame.new(spawnLoc.CFrame.Position + Vector3.new(0,2,0)) * CFrame.Angles(0, math.rad(180), 0))
    player.Character.PrimaryPart.Anchored = false

    -- loadout
    local load = self.playerdata[player.Name].loadout
    if not load then
        self:InitPlayerData(player)
        load = self.playerdata[player.Name].loadout
        if not load then
            -- callback, shouldn't happen
            player.Character.Humanoid:TakeDamage(1000)
            task.delay(0.5, function()
                self:SpawnPlayer(player)
            end)
        end
    end

    for _, abi in pairs(load.ability) do
        task.spawn(function()
            Ability.Add(player, abi)
        end)
    end
    
    for _, wep in pairs({load.weapon.primary, load.weapon.secondary, "Knife"}) do
        task.spawn(function()
            Weapon.Add(player, wep, wep == "Knife") -- final bool is forceEquip. forceEquip if knife
        end)
    end

    local conn
    conn = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if self.status ~= "running" then conn:Disconnect() return end
        if hum.Health <= 0 then self:Died(player) conn:Disconnect() return end
        if hum.Health < 100 then hum.Health = 100 return end
    end)
end

function Animations:AddBuyMenu(player)
    if self.playerdata[player.Name].buymenu then return end
    local c = self._buyMenuGui:Clone()
    c.Parent = player.PlayerGui
    c.ResetOnSpawn = false

    self.playerdata[player.Name].connections.buymenu = {
        c:WaitForChild("AbilitySelected").OnServerEvent:Connect(function(_, ability, slot)
            self.playerdata[player.Name].loadout.ability[slot] = ability
            Ability.Add(player, ability)
        end),
        c:WaitForChild("WeaponSelected").OnServerEvent:Connect(function(_, weapon, slot)
            self.playerdata[player.Name].loadout.weapon[slot] = weapon
            Weapon.Add(player, weapon)
        end)
    }

    self.playerdata[player.Name].buymenu = c
    return c
end

function Animations:RemoveBuyMenu(player)
    if self.playerdata[player.Name].buymenu then
        self.playerdata[player.Name].buymenu:Destroy()
    end
    if self.playerdata[player.Name].connections.buymenu then
        for i, v in pairs(self.playerdata[player.Name].connections.buymenu) do
            v:Disconnect()
        end
        self.playerdata[player.Name].connections.buymenu = {}
    end
end

-- Died

function Animations:Died(player)
    self:DiedCamera(player)

    task.spawn(function()
        Weapon.ClearPlayerInventory(player)
        Ability.ClearPlayerInventory(player)
    end)

    if self.customDiedCallbacks then
        for _, extraDiedFunc in pairs(self.customDiedCallbacks) do
            extraDiedFunc(player)
        end
    end

    task.delay(self.respawnLength, function()
        if self.status == "running" then
            self:SpawnPlayer(player)
        end
    end)
end

function Animations:DiedCamera(player)
    local killer = player.Character:FindFirstChild("DamageTag") and player.Character.DamageTag.Value or player
    local camerac = self.objects.deathCameraScript:Clone()
    camerac:WaitForChild("killerObject").Value = killer
    camerac.Parent = player.Character
    self.playerdata[player.Name].deathCameraScript = camerac
end

return Animations
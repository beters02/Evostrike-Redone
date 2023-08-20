local Deathmatch = {
    minimumPlayers = 1,
    respawnLength = 4,

    isWaiting = false,
    status = "running",
    playerdata = {},
    buymenu = nil
}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)
local BotModule = require(Framework.sm_bots.Location)
local RunService = game:GetService("RunService")
local GamemodeLoc = game:GetService("ServerScriptService"):WaitForChild("gamemode"):WaitForChild("class"):WaitForChild("Deathmatch")
local Spawns = GamemodeLoc:WaitForChild("Spawns")

local diedGui = GamemodeLoc:WaitForChild("DeathmatchDeathGui")
local buyMenuGui = GamemodeLoc:WaitForChild("BuyMenu")
local diedMainEvent = game.ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local deathCamera = GamemodeLoc:WaitForChild("deathCamera")

function Deathmatch:Start()
    local min = self.minimumPlayers or 1

    self.waitingThread = false
    if #Players:GetPlayers() < min then
        self.waitingThread = task.spawn(function()
            repeat
                task.wait(1)
            until #Players:GetPlayers() >= min
            self:PostWait(Players:GetPlayers())
        end)
        return
    end

    self:PostWait(Players:GetPlayers())
    print("Gamemode " .. self.currentGamemode .. " started!")
end

function Deathmatch:Stop()

    -- set status
    self.status = "dead"

    -- disconnect connections
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    if self.playerDiedRegisterConn then self.playerDiedRegisterConn:Disconnect() end
    if self.isWaiting then
        coroutine.yield(self.waitingThread)
        return
    end

    -- remove all weapons and abilities
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()

    -- unload all characters
    for i, v in pairs(Players:GetPlayers()) do
        v.Character.Humanoid:TakeDamage(1000)
        v.Character = nil
    end

end

function Deathmatch:PostWait(players)

    -- add any players that have already joined
    for i, v in pairs(players) do
        task.spawn(function()
            self:InitPlayer(v)
            self:SpawnPlayer(v)
        end)
    end

    -- init player added connection
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    self.playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self:InitPlayer(player)
        self:SpawnPlayer(player)
    end)

    -- init player died registration connection
    if self.playerDiedRegisterConn then self.playerDiedRegisterConn:Disconnect() end
    self.playerDiedRegisterConn = diedMainEvent.OnServerEvent:Connect(function(player)
        self:Died(player)
    end)

    -- remove barriers
    if workspace:FindFirstChild("Barriers") then
        workspace.Barriers.Parent = game:GetService("ReplicatedStorage")
    end

end

function Deathmatch:InitPlayer(player)
    self.playerdata[player.Name] = {
        loadout = {weapon = {primary = "AK47", secondary = "Glock17"}, ability = {primary = "Dash", secondary = "Molly"}},
        connections = {buymenu = {}}
    }
end

function Deathmatch:SpawnPlayer(player)
    player:LoadCharacter()
    task.wait()

    player.Character.Humanoid.Health = 100

    -- teleport player to spawn
    local spawnLoc = self:RequestSpawnPoint(player)

    player.Character.PrimaryPart.Anchored = true
    player.Character:SetPrimaryPartCFrame(spawnLoc.CFrame + Vector3.new(0,2,0))
    player.Character.PrimaryPart.Anchored = false

    -- playerdata sanity check
    if not self.playerdata[player.Name] then self:InitPlayer(player) end
    local loadout = self.playerdata[player.Name].loadout

    -- add abilities
    Ability.Add(player, loadout.ability.primary)
    Ability.Add(player, loadout.ability.secondary)

    -- add weapons
    Weapon.Add(player, loadout.weapon.primary)
    --Weapon.Add(player, loadout.weapon.secondary)
    Weapon.Add(player, "Knife", true)

    -- buy menu
    self:AddBuyMenu(player)

end

function Deathmatch:Died(player)
    task.spawn(function()
        Weapon.ClearPlayerInventory(player)
        Ability.ClearPlayerInventory(player)
    end)

    -- give player gui (handle respawn)
    self:HandleDeathGuiRespawn(player)

    -- remove buy menu
    self:RemoveBuyMenu(player)
end

function Deathmatch:RequestSpawnPoint(player): Part
    local points = {}
    local lowest
    local spawns = Spawns:GetChildren()

    for i, v in pairs(Players:GetPlayers()) do
        if not v.Character then continue end

        for _, spwn in pairs(spawns) do
            if not points[spwn.Name] then points[spwn.Name] = 10000 end
            points[spwn.Name] -= (v.Character.HumanoidRootPart.CFrame.Position - spwn.CFrame.Position).Magnitude

            if not lowest or points[spwn.Name] < lowest[2] then
                lowest = {spwn, points[spwn.Name]}
            end
        end
    end

    lowest = lowest and lowest[1] or spawns[math.random(1, #spawns)]
    return lowest
end

function Deathmatch:HandleDeathGuiRespawn(player) -- Handles Death GUI, Camera and Respawn
    local killer = player.Character:FindFirstChild("DamageTag") and player.Character.DamageTag.Value or player

    local camerac = deathCamera:Clone()
    camerac:WaitForChild("killerObject").Value = killer
    camerac.Parent = player.Character

    local c = diedGui:Clone()
    c:SetAttribute("KilledPlayerName", killer.Name)

    -- connect respawn remote
    local conn
    conn = c:WaitForChild("Remote").OnServerEvent:Connect(function(plr, action)
        if action == "Respawn" then
            camerac:WaitForChild("Destroy"):FireClient(player)
            task.wait()
            self:SpawnPlayer(player)
            conn:Disconnect()
            conn = nil
            c:Destroy()
        else
            c.Enabled = false
            local menu = self:AddBuyMenu(player)
            menu.Enabled = true
            menu:WaitForChild("Back").OnServerEvent:Once(function()
                menu:Destroy()
                c.Enabled = true
            end)
        end
    end)

    c.Parent = player.PlayerGui
end

function Deathmatch:AddBuyMenu(player)
    -- add buy menu
    local c = buyMenuGui:Clone()
    c.Parent = player.PlayerGui
    self.playerdata[player.Name].connections.buymenu = {
        c:WaitForChild("AbilitySelected").OnServerEvent:Connect(function(plr, ability, slot)
            self.playerdata[player.Name].loadout.ability[slot] = ability
        end),
        c:WaitForChild("WeaponSelected").OnServerEvent:Connect(function(plr, weapon, slot)
            self.playerdata[player.Name].loadout.weapon[slot] = weapon
        end)
    }
    self.playerdata[player.Name].buymenu = c
    return c
end

function Deathmatch:RemoveBuyMenu(player)
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

return Deathmatch
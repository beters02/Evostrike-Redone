local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)

local Deathmatch = {
    minimumPlayers = 1,
    maximumPlayers = 8,
    respawnLength = 4,
    startWithBarriers = false,
    playerDataEnabled = true,
    botsEnabled = false,

    playerdata = {},
    buymenu = nil
}

local diedGui
local buyMenuGui

-- Init objects and such
function Deathmatch._init(self)
    -- Add objects
    self.objects.moduleLocation = Deathmatch.objects.baseLocation.Parent.Deathmatch
    self.objects.spawns = Deathmatch.objects.moduleLocation.Spawns

    -- Init var
    diedGui = self.objects.moduleLocation.DeathmatchDeathGui
    buyMenuGui = self.objects.moduleLocation.BuyMenu

    return self
end

-- Base Functions

function Deathmatch:InitPlayerData(player)
    self.playerdata[player.Name] = {
        loadout = {weapon = {primary = "AK47", secondary = "Glock17"}, ability = {primary = "Dash", secondary = "Molly"}},
        connections = {buymenu = {}},
        var = {firstSpawn = true},
        deathCameraScript = false
    }
end

function Deathmatch:SpawnPlayer(player)
    task.spawn(function()
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
        end

        -- if this is a player's first spawn, we will simply only add the Loadout/Respawn gui
        if self.playerdata[player.Name].var.firstSpawn then
            self.playerdata[player.Name].var.firstSpawn = false

            -- set camera pos to preset pos (todo: add to config)
            local _setCam = self.objects.moduleLocation.setCameraPositionScript:Clone()
            _setCam.Parent = player.PlayerGui

            local gui = self:DiedGui(player, true, {_setCam})
            gui.MainFrame.KilledLabel.Visible = false -- disable "Killed You!" text
            gui.MainFrame.RespawnButton.Text = "Spawn"
            return
        end

        if self.playerdata[player.Name] and self.playerdata[player.Name].deathCameraScript then
            self.playerdata[player.Name].deathCameraScript:WaitForChild("Destroy"):FireClient(player)
            print('yuh')
        end

        player:LoadCharacter()
        task.wait()

        player.Character.Humanoid.Health = 100

        -- teleport player to spawn
        local spawnLoc = self:RequestSpawnPoint(player)

        player.Character.PrimaryPart.Anchored = true
        player.Character:SetPrimaryPartCFrame(spawnLoc.CFrame + Vector3.new(0,2,0))
        player.Character.PrimaryPart.Anchored = false

        -- playerdata sanity check
        if not self.playerdata[player.Name] then self:InitPlayerData(player) end
        local loadout = self.playerdata[player.Name].loadout

        -- add abilities
        Ability.Add(player, loadout.ability.primary)
        Ability.Add(player, loadout.ability.secondary)

        -- add weapons
        Weapon.Add(player, loadout.weapon.primary, true)
        Weapon.Add(player, loadout.weapon.secondary)
        Weapon.Add(player, "Knife")

        -- buy menu
        self:AddBuyMenu(player)
    end)
end

function Deathmatch:Died(player)

    -- remove buy menu
    self:RemoveBuyMenu(player)

    -- give player gui (handle respawn)
    self:DiedGui(player)
    self:DiedCamera(player)

    task.spawn(function()
        Weapon.ClearPlayerInventory(player)
        Ability.ClearPlayerInventory(player)
    end)
end

function Deathmatch:DiedGui(player, ignoreKiller, destroyOnDestroy) -- Handles Death GUI, Camera and Respawn

    local died = diedGui:Clone()
    local killer

    -- grab killer from damage tag and set text
    if not ignoreKiller then
        died:SetAttribute("KilledPlayerName", (player.Character:FindFirstChild("DamageTag") and player.Character.DamageTag.Value or player).Name)
    end

    -- we need to recycle the menu to
    -- prevent spam instancing
    local menu = self:AddBuyMenu(player, died)
    menu.Enabled = false
    menu.KeyboardInputConnect:Destroy()

    -- connect respawn remote
    local conn
    conn = died:WaitForChild("Remote").OnServerEvent:Connect(function(plr, action)
        if action == "Respawn" then
            task.wait()

            -- YOU MUST CALL REMOVE BUY MENU
            -- MEMORY LEAK MOMENT
            self:RemoveBuyMenu(player)

            conn:Disconnect()
            conn = nil
            died:Destroy()

            if destroyOnDestroy then
                for i, v in pairs(destroyOnDestroy) do
                    v:Destroy()
                end
            end

            task.wait()
            
            -- Call SpawnPlayer last for gameplay stuff
            self:SpawnPlayer(player)
        elseif action == "Back" then
            menu.Enabled = false
            died.Enabled = true
        elseif action == "Loadout" then
            died.Enabled = false
            menu.Enabled = true
        end
    end)

    died.Parent = player.PlayerGui
    return died
end

-- Deathmatch Functions

function Deathmatch:RequestSpawnPoint(player): Part
    local points = {}
    local lowest
    local spawns

    -- if we have a small player count, we want to only spawn
    -- them in zone 1 which will be a smaller area of the map

    -- get spawn location in zones based on amount of players in game
    if self:GetTotalPlayerCount() <= 0.5 * self.maximumPlayers then
        spawns = self.objects.spawns.Zone1:GetChildren()
    else
        spawns = self.objects.spawns:GetDescendants()
    end

    for i, v in pairs(Players:GetPlayers()) do
        if not v.Character then continue end

        for _, spwn in pairs(spawns) do
            if not spwn:IsA("Part") then continue end

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

function Deathmatch:AddBuyMenu(player, diedgui)

    -- add buy menu
    local c = buyMenuGui:Clone()

    -- if it's a dead buy menu, add object values
    if diedgui then
        local remoteObject = Instance.new("ObjectValue", c)
        remoteObject.Name = "RemoteObject"
        remoteObject.Value = diedgui.Remote
    end

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

    print('added buy menu!')
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
local Deathmatch = {
    minimumPlayers = 1,
    respawnLength = 4,
    maximumPlayers = 8,

    isWaiting = false,
    status = "running",
    playerdata = {},
    buymenu = nil
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)
local BotModule = require(Framework.sm_bots.Location)
local RunService = game:GetService("RunService")
local GamemodeLoc = game:GetService("ServerScriptService"):WaitForChild("gamemode"):WaitForChild("class"):WaitForChild("Deathmatch")
local Spawns = GamemodeLoc:WaitForChild("Spawns")
local MessagingService = game:GetService("MessagingService")

local diedGui = GamemodeLoc:WaitForChild("DeathmatchDeathGui")
local buyMenuGui = GamemodeLoc:WaitForChild("BuyMenu")
local diedMainEvent = game.ReplicatedStorage:WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathRE")
local deathCamera = GamemodeLoc:WaitForChild("deathCamera")

function Deathmatch:Start()
    local min = self.minimumPlayers or 1

    self.nextUpdateTick = tick()
    self.waitingThread = false

    -- init removing conn
    self.playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        if self.playerdata[player.Name] then
            pcall(function()
                for i, v in pairs(self.playerdata[player.Name].connections) do
                    v:Disconnect()
                end
            end)
            self.playerdata[player.Name] = nil
        end
    end)

    -- wait if minimum players not reached
    if #Players:GetPlayers() < min then
        self.waitingThread = task.spawn(function()
            repeat
                task.wait(1)
            until #Players:GetPlayers() >= min
            self:PostWait(Players:GetPlayers())
            print("Gamemode " .. self.currentGamemode .. " started!")
        end)
        return
    end

    -- start otherwise
    self:PostWait(Players:GetPlayers())
    print("Gamemode " .. self.currentGamemode .. " started!")
end

function Deathmatch:Stop()

    -- set status
    self.status = "dead"

    -- disconnect connections
    if self.playerAddedConnection then self.playerAddedConnection:Disconnect() end
    if self.isWaiting then
        coroutine.yield(self.waitingThread)
        return
    end
    self.serverInfoUpdateConn:Disconnect()

    -- remove all weapons and abilities
    Ability.ClearAllPlayerInventories()
    Weapon.ClearAllPlayerInventories()

    -- unload all characters
    for i, v in pairs(Players:GetPlayers()) do
        v.Character.Humanoid:TakeDamage(1000)
        v.Character = nil
    end

    -- clear temps
    for i, v in pairs(workspace:WaitForChild("Temp"):GetChildren()) do
        v:Destroy()
    end

    for i, v in pairs(ReplicatedStorage:WaitForChild("temp"):GetChildren()) do
        v:Destroy()
    end

    -- destroy bots
    for i, v in pairs(CollectionService:GetTagged("Bot")) do
        task.spawn(function()
            v.Humanoid:TakeDamage(1000)
            task.wait(0.1)
            v:Destroy()
        end)
    end

    task.wait(0.1)

    print('Gamemode Lobby Stopped')
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
    task.spawn(function()
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
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
        if not self.playerdata[player.Name] then self:InitPlayer(player) end
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
    task.spawn(function()
        Weapon.ClearPlayerInventory(player)
        Ability.ClearPlayerInventory(player)
    end)

    -- remove buy menu
    self:RemoveBuyMenu(player)

    -- give player gui (handle respawn)
    self:HandleDeathGuiRespawn(player)
    
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

    local died = diedGui:Clone()
    died:SetAttribute("KilledPlayerName", killer.Name)

    -- we need to recycle the menu to
    -- prevent spam instancing
    local menu = self:AddBuyMenu(player, died)
    menu.Enabled = false
    menu.KeyboardInputConnect:Destroy()

    -- connect respawn remote
    local conn
    conn = died:WaitForChild("Remote").OnServerEvent:Connect(function(plr, action)
        if action == "Respawn" then
            camerac:WaitForChild("Destroy"):FireClient(player)
            task.wait()

            -- YOU MUST CALL REMOVE BUY MENU
            -- MEMORY LEAK MOMENT
            self:RemoveBuyMenu(player)

            conn:Disconnect()
            conn = nil
            died:Destroy()

            task.wait()
            
            -- Call SpawnPlayer last for gameplay stuff
            self:SpawnPlayer(player)
        elseif action == "Back" then
            menu.Enabled = false
            died.Enabled = true
            print('worked2')
        elseif action == "Loadout" then
            died.Enabled = false
            menu.Enabled = true
            print('loadout2')
        end
    end)

    died.Parent = player.PlayerGui
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

function Deathmatch:GetTotalPlayerCount()
    local _count = 0
    for i, v in pairs(self.playerdata) do
        if v then _count += 1 end
    end
    return _count
end

return Deathmatch
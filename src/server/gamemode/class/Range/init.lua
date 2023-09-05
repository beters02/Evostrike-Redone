local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)

local Range = {
    botsEnabled = true,
    playerDataEnabled = true,
    playerdata = {}
}

local buyMenuGui

-- Init objects and such
function Range._init(self)
    -- Add objects
    self.objects.moduleLocation = Range.objects.baseLocation.Parent.Range
    buyMenuGui = Range.objects.baseLocation.Parent.Deathmatch.BuyMenu
    return self
end

function Range:InitPlayerData(player)
    self.playerdata[player.Name] = {
        loadout = {weapon = {primary = "AK47", secondary = "Glock17"}, ability = {primary = "Dash", secondary = "Molly"}},
        connections = {buymenu = {}},
        deathCameraScript = false
    }
end

function Range:AddBuyMenu(player, diedgui)

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

function Range:RemoveBuyMenu(player)
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

function Range:SpawnPlayer(player)
    task.spawn(function()
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
        end

        if self.playerdata[player.Name] and self.playerdata[player.Name].deathCameraScript then
            self.playerdata[player.Name].deathCameraScript:WaitForChild("Destroy"):FireClient(player)
            print('yuh')
        end

        player:LoadCharacter()
        task.wait()

        player.Character.Humanoid.Health = 100

        -- teleport player to spawn
        local spawnLoc = self.objects.spawns.Default
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

return Range
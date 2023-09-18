local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Ability = require(Framework.Ability.Location)
local Weapon = require(Framework.Weapon.Location)

local Range = {
    botsEnabled = true,
    playerDataEnabled = true,
    startWithMenuOpen = false,
    playerdata = {},
    shieldEnabled = true,
    startingShield = 50,
    startingHelmet = true,
    startingHealth = 100,
}

local buyMenuGui
local bToBuy

-- Init objects and such
function Range._init(self)
    -- Add objects
    self.objects.moduleLocation = Range.objects.baseLocation.Parent.Range
    buyMenuGui = self.objects.moduleLocation.BuyMenu
    bToBuy = self.objects.moduleLocation.PressBGui
    return self
end

function Range:InitPlayerData(player)
    self.playerdata[player.Name] = {
        loadout = {weapon = {primary = "AK103", secondary = "Glock17"}, ability = {primary = "Dash", secondary = "Molly"}},
        connections = {buymenu = {}},
        deathCameraScript = false
    }
end

function Range:SpawnPlayer(player)
    task.spawn(function()
        if not player:GetAttribute("Loaded") then
            repeat task.wait() until player:GetAttribute("Loaded")
        end

        if self.playerdata[player.Name] and self.playerdata[player.Name].deathCameraScript then
            self.playerdata[player.Name].deathCameraScript:WaitForChild("Destroy"):FireClient(player)
        end

        player:LoadCharacter()
        task.wait(0.25)

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
        Weapon.Add(player, loadout.weapon.primary)
        Weapon.Add(player, loadout.weapon.secondary)
        Weapon.Add(player, "Knife", true)

        -- buy menu
        self:AddBuyMenu(player)
    end)
end

function Range:AddBuyMenu(player)
    if self.playerdata[player.Name].buymenu then return end
    local c = buyMenuGui:Clone()
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

function Range:Died(player)
    -- give player gui (handle respawn)
    self:DiedGui(player)
    self:DiedCamera(player)

    task.spawn(function()
        Weapon.ClearPlayerInventory(player)
        Ability.ClearPlayerInventory(player)
    end)
end

return Range
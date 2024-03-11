local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(Framework.Module.lib.fc_tables)
local Strings = require(Framework.Module.lib.fc_strings)
local DiedBind = Framework.Module.EvoPlayer.Events.PlayerDiedBindable
local DiedEvent = Framework.Module.EvoPlayer.Events.PlayerDiedRemote

local hud = {}

function hud.initialize(player: Player)
    hud.enabled = true

    hud.player = player
    hud.gui = player.PlayerGui:WaitForChild("HUD")
    hud.infocv = hud.gui:WaitForChild("InfoCanvas")
    hud.infomainfr = hud.infocv:WaitForChild("MainFrame")
    hud.healthfr = hud.infomainfr:WaitForChild("HealthFrame")
    hud.weaponfr = hud.gui:WaitForChild("WeaponFrame")
    hud.charfr = hud.infomainfr:WaitForChild("CharacterFrame")
    hud.killfr = hud.gui:WaitForChild("KillfeedFrame")

    hud.playerConnections = {}
    hud.killConnections = {}
    hud = hud.initKillfeeds(hud)

    hud.pccount = 0 -- total playerconn

    hud.health = require(script:WaitForChild("fc_health")).init(hud)
    hud.killfeed = require(script.fc_killfeed).init(hud)
    hud.yourkillfeed = require(script.fc_killfeed).init({killfr = hud.gui:WaitForChild("YourKillfeedFrame"), yours = true, upLength = 2})

    -- init var and resetvar
    local var = {lastSavedHealth = 0}
    hud.var = Tables.clone(var)
    hud._resetVar = function() hud.var = var end

    -- init object animations
    local weaponBar = hud.gui:WaitForChild("WeaponBar")
    hud._weaponLabelSizes = {}
    hud._magLabelSize = hud.weaponfr.CurrentMagLabel.Size :: UDim2

    local abilityBar = hud.gui:WaitForChild("AbilityBar")
    hud._abilityLabelSizes = {}

    for _, str in pairs({"Primary", "Secondary", "Ternary"}) do
        hud._weaponLabelSizes[str] = weaponBar:WaitForChild(str):WaitForChild("EquippedIconLabel").Size

        if str == "Ternary" then
            continue
        end

        hud._abilityLabelSizes[str] = abilityBar:WaitForChild(str):WaitForChild("IconImage").Size
    end

    -- wait for children
    for _, v in pairs({hud.healthfr, hud.weaponfr}) do
        for _, ch in pairs(v:GetChildren()) do repeat task.wait() until ch end
    end

    return hud
end

function hud.initKillfeeds(self)

    -- connect your death
    self.killConnections._self = DiedBind.Event:Connect(function(killer)
        killer = killer or self.player
        self.killfeed:addItem(killer, self.player)
    end)

    -- connect other players diedevent to killfeed
    self.killConnections._other = DiedEvent.OnClientEvent:Connect(function(killed, killer)
        killer = killer or self.player
        self.killfeed:addItem(killer, killed)

        -- your kill feed
        if killer == self.player then
            self.yourkillfeed:addItem(killer, killed)
        end
    end)

    return self
end

function bulletFireTween()
    local goalmod = 1.1
    local goalrot = math.random(5, 8)
    goalrot *= (math.random(1,2) == 1) and 1 or -1
    
    local ft1 = TweenService:Create(
        hud.weaponfr.CurrentMagLabel,
        TweenInfo.new(0.3, Enum.EasingStyle.Bounce),
        {Size = UDim2.fromScale(hud._magLabelSize.X.Scale * goalmod, hud._magLabelSize.Y.Scale * goalmod), Rotation = goalrot}
    )

    local ft2 = TweenService:Create(
        hud.weaponfr.CurrentMagLabel,
        TweenInfo.new(0.3),
        {Size = hud._magLabelSize, Rotation = 0}
    )

    ft1:Play()
    ft1.Completed:Wait()
    ft2:Play()
    ft1:Destroy()
    ft2:Destroy()
end

function equipGunTween(slot)
    slot = Strings.firstToUpper(slot)
    local label = hud.gui.WeaponBar[slot].EquippedIconLabel

    local goalmod = math.random(11, 13) / 10
    local startSize: UDim2 = hud._weaponLabelSizes[slot]
    local goalSize = UDim2.fromScale(startSize.X.Scale * goalmod, startSize.Y.Scale * goalmod)

    local ft1 = TweenService:Create(
        label,
        TweenInfo.new(0.06),
        {Size = goalSize}
    )

    local ft2 = TweenService:Create(
        label,
        TweenInfo.new(0.09),
        {Size = startSize}
    )

    ft1:Play()
    ft1.Completed:Wait()
    ft2:Play()
    ft1:Destroy()
    ft2:Destroy()
end

function reloadGunTween(newMag, newTotal)
    local oldMagValue = Instance.new("IntValue")
    oldMagValue.Value = tonumber(hud.weaponfr.CurrentMagLabel.Text)

    local oldTotalValue = Instance.new("IntValue")
    oldTotalValue.Value = tonumber(hud.weaponfr.CurrentTotalAmmoLabel.Text)
    
    local ft1 = TweenService:Create(
        oldMagValue,
        TweenInfo.new(0.3, Enum.EasingStyle.Cubic),
        {Value = newMag}
    )

    local ft2 = TweenService:Create(
        oldTotalValue,
        TweenInfo.new(0.35, Enum.EasingStyle.Cubic),
        {Value = newTotal}
    )

    local conn = RunService.RenderStepped:Connect(function()
        hud.weaponfr.CurrentMagLabel.Text = tostring(oldMagValue.Value)
        hud.weaponfr.CurrentTotalAmmoLabel.Text = tostring(oldTotalValue.Value)
    end)

    ft1:Play()
    ft2:Play()
    ft2.Completed:Wait()

    hud.weaponfr.CurrentMagLabel.Text = tostring(newMag)
    hud.weaponfr.CurrentTotalAmmoLabel.Text = tostring(newTotal)

    conn:Disconnect()
    ft1:Destroy()
    ft2:Destroy()
    oldMagValue:Destroy()
    oldTotalValue:Destroy()
end

function useAbilityTween(slot)
    slot = Strings.firstToUpper(slot)
    local label = hud.gui.AbilityBar[slot].IconImage

    local goalmod = 1.1
    local goalrot = math.random(7, 10)
    local startSize: UDim2 = hud._abilityLabelSizes[slot]
    local goalSize = UDim2.fromScale(startSize.X.Scale * goalmod, startSize.Y.Scale * goalmod)

    local ft1 = TweenService:Create(
        label,
        TweenInfo.new(0.32, Enum.EasingStyle.Circular),
        {Size = goalSize, Rotation = goalrot * (math.random(1,2) == 1 and 1 or -1)}
    )

    local ft2 = TweenService:Create(
        label,
        TweenInfo.new(0.48, Enum.EasingStyle.Circular),
        {Size = startSize, Rotation = 0}
    )

    ft1:Play()
    ft1.Completed:Wait()
    ft2:Play()
    ft1:Destroy()
    ft2:Destroy()
end

--

function hud:ConnectPlayer()
    hud.pccount = 1

    -- update (health)
    local upc = hud.pccount
    self.playerConnections.Update = RunService.RenderStepped:Connect(function()
        if not self.player.Character then
            warn("Framework.cm_hud: There is no character for this player.. disconnecting this connection.")
            self.playerConnections[upc]:Disconnect()
            self.playerConnections[upc] = nil
            table.remove(self.playerConnections, upc)
            return
        end

        hud.health:update()
    end)

    self.playerConnections.FireBullet = script:WaitForChild("FireBullet").Event:Connect(function()
        bulletFireTween()
    end)

    self.playerConnections.EquipGun = script:WaitForChild("EquipGun").Event:Connect(function(slot)
        equipGunTween(slot)
    end)

    self.playerConnections.ReloadGun = script:WaitForChild("ReloadGun").Event:Connect(function(newMag, newTotal)
        reloadGunTween(newMag, newTotal)
    end)

    self.playerConnections.UseAbility = script:WaitForChild("UseAbility").Event:Connect(function(slot)
        useAbilityTween(slot)
    end)
end

function hud:DisconnectPlayer()
    self._resetVar()

    for i, v in pairs(self.playerConnections) do
        v:Disconnect()
    end
    self.playerConnections = {}

    for i, v in pairs({"Primary", "Secondary"}) do
        self.gui.WeaponBar[v].Visible = false
        self.gui.AbilityBar[v].Visible = false
    end

    self.gui.WeaponBar.Ternary.Visible = false

end

function hud:Enable()
    if not hud.gui then
        return
    end
    for _, component in pairs(hud.gui:GetChildren()) do
        local _, err = pcall(function()
            if component:IsA("ScreenGui") then
                component.Enabled = true
            else
                component.Visible = true
            end
        end)
        if err then warn(err) end
    end
    hud.enabled = true
end

function hud:Disable()
    if not hud.gui then
        return
    end
    for _, component in pairs(hud.gui:GetChildren()) do
        local _, err = pcall(function()
            if component:IsA("ScreenGui") then
                component.Enabled = false
            else
                component.Visible = false
            end
        end)
        if err then warn(err) end
    end
    hud.enabled = false
end

return hud
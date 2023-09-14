local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local ServerScriptService = game:GetService("ServerScriptService")
local Gamemode = require(Framework.Module.server.gamemode.m_gamemode)
local Character = script.Parent.Parent

local Shield = 0
if Gamemode.currentClass.shieldEnabled then
    Shield = Gamemode.currentClass.startingShield
end

local function setShield(newShield)
    Shield = newShield
    Character:SetAttribute("Shield", Shield)
end

setShield(Shield)

local Helmet = Gamemode.currentClass.startingHelmet or false
local function setHelmet(bool)
    Helmet = bool
    Character:SetAttribute("Helmet", bool)
end

setHelmet(Helmet)

local DamagedEvent = script.Parent:WaitForChild("PlayerDamaged")
DamagedEvent.OnServerEvent:Connect(function(player, newHealth, damageTaken, hitPartName, weaponName)
    if not damageTaken or not hitPartName or not weaponName then return end

    local healthAdd = 0

    if string.match(string.lower(hitPartName), "head") then
        local weaponOptions = ServerScriptService.weapon.config[weaponName or "glock17"]
        if Helmet then

            if weaponOptions.damage.destroysHelmet then
                Helmet = false
                setHelmet(false)
            end

            local predmgtaken = damageTaken
            damageTaken *= weaponOptions.damage.helmetMultiplier
            healthAdd += predmgtaken - damageTaken
        end
    end

    if Shield > 0 then
        if Shield >= damageTaken then
            setShield(Shield - damageTaken)
            healthAdd += damageTaken
        else
            healthAdd += damageTaken - Shield
            setShield(0)
        end
    end

    if healthAdd > 0 then
        player.Character.Humanoid.Health += healthAdd
    end
end)

local SetShieldAll = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("setShieldAll")
SetShieldAll.Event:Connect(function(newShield)
    setShield(Shield)
end)
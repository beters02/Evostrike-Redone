local options = require(script.Parent:WaitForChild("GameOptions"))
local playerdata = require(script.Parent:WaitForChild("PlayerData"))
local gamedata = require(script.Parent:WaitForChild("GameData"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Player = require(Framework.Module.EvoPlayer)
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local GamemodeEvents = ReplicatedStorage:WaitForChild("GamemodeEvents")
local BuyMenuEvents = GamemodeEvents:WaitForChild("BuyMenu")

local BuyMenu = {
    _connections = {}
}

function BuyMenu:init()
    BuyMenuEvents.AttemptWeaponPurchase.OnServerInvoke = attemptWeaponPurchase
    BuyMenuEvents.AttemptAbilityPurchase.OnServerInvoke = attemptAbilityPurchase
    BuyMenuEvents.AttemptEquipmentPurchase.OnServerInvoke = attemptEquipmentPurchase

    -- init BuyMenu Prices
    local defGui = script.Parent.HUD.Guis.BuyMenu.Gui
    setAbilityFramesPrice(defGui.MainFrame.AbilityMiddleFrame.Movement.ContentFrame)
    setAbilityFramesPrice(defGui.MainFrame.AbilityMiddleFrame.Utility.ContentFrame)
    setWeaponFramesPrice(defGui.MainFrame.GunMiddleFrame.Rifles.ContentFrame)
    setWeaponFramesPrice(defGui.MainFrame.GunMiddleFrame.Pistols.ContentFrame)
    setEquipmentFramesPrice(defGui.MainFrame.GunMiddleFrame.Equipment.ContentFrame)
end

--@summary Hides Inaccessible Weapons/Abilities/Equipment from BuyMenu based on team
function BuyMenu:initPlayerBuyMenu(gui, team)
    local buyMenuKey = "BUY_MENU_" .. string.upper(team)
    local buyMenuEnum = options.Enum[buyMenuKey]
    for _, v in pairs(gui.MainFrame.AbilityMiddleFrame.Movement.ContentFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        if not buyMenuEnum.primaryAbilities[string.lower(v.Name)] then
            v.Visible = false
        end
    end
    for _, v in pairs(gui.MainFrame.AbilityMiddleFrame.Utility.ContentFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        if not buyMenuEnum.secondaryAbilities[string.lower(v.Name)] then
            v.Visible = false
        end
    end
    for _, v in pairs(gui.MainFrame.GunMiddleFrame.Rifles.ContentFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        if not buyMenuEnum.rifles[string.lower(v.Name)] then
            v.Visible = false
        end
    end
    for _, v in pairs(gui.MainFrame.GunMiddleFrame.Pistols.ContentFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        if not buyMenuEnum.pistols[string.lower(v.Name)] then
            v.Visible = false
        end
    end
    for _, v in pairs(gui.MainFrame.GunMiddleFrame.Equipment.ContentFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        if not buyMenuEnum.equipment[string.lower(v.Name)] then
            v.Visible = false
        end
    end
end

--

function setAbilityFramesPrice(contentFrame)
    for _, v in pairs(contentFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        local price = options.Enum.ABILITY_COST[string.lower(v.Name)] or options.Enum.ABILITY_COST.default
        v.PriceLabel.Text = "$" .. tostring(price)
    end
end

function setWeaponFramesPrice(contentFrame)
    for _, v in pairs(contentFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        local price = options.Enum.WEAPON_COST[string.lower(v.Name)] or options.Enum.WEAPON_COST.default
        v.PriceLabel.Text = "$" .. tostring(price)
    end
end

function setEquipmentFramesPrice(contentFrame)
    for _, v in pairs(contentFrame:GetChildren()) do
        if not v:IsA("Frame") then continue end
        local price = options.Enum.EQUIPMENT_COST[string.lower(v.Name)]
        v.PriceLabel.Text = "$" .. tostring(price)
    end
end

function attemptWeaponPurchase(player, weapon)
    if gamedata.status == "inactive" or not gamedata.canBuy then
        return false, "Can't use buy menu at this time."
    end

    local price = options.Enum.WEAPON_COST[weapon] or options.Enum.WEAPON_COST.default
    if playerdata._get(player, "money") < price then
        return false, "Can't afford weapon."
    end

    playerdata._dec(player, "money", price)
    GamemodeEvents.HUD.SetMoney:FireClient(player, playerdata._get(player, "money"))

    local inv = playerdata._get(player, "inventory")
    local slot = require(WeaponService:GetWeaponModule(weapon)).inventorySlot

    if inv.weapons[slot] then
        -- drop weapon
        WeaponService:RemoveWeapon(player, slot)
    end

    WeaponService:AddWeapon(player, weapon)

    return true
end

function attemptAbilityPurchase(player, ability)
    if gamedata.status == "inactive" or not gamedata.canBuy then
        return false, "Can't use buy menu at this time."
    end

    local price = options.Enum.ABILITY_COST[ability] or options.Enum.ABILITY_COST.default
    if playerdata._get(player, "money") < price then
        return false, "Can't afford ability."
    end

    local inv = playerdata._get(player, "inventory")
    local slot = require(AbilityService:GetAbilityModule(ability)).inventorySlot

    if inv.abilities[slot] then
        if inv.abilities[slot].name ~= ability then
            return false, "You already have an ability in this slot"
        end
        local maxAmnt = options.Enum.ABILITY_MAX_AMOUNT[ability] or options.Enum.ABILITY_MAX_AMOUNT.default
        if inv.abilities[slot].amount >= maxAmnt then
            return false, "You already have the maximum owned amount."
        end
        AbilityService:AddAbility(player, ability, inv.abilities[slot].amount + 1)
        return true
        --AbilityService:RemoveAbility(player, slot)
    else
        inv.abilities[slot] = {name = ability, amount = 1}
        AbilityService:AddAbility(player, ability, 1)
    end

    playerdata._dec(player, "money", price)
    GamemodeEvents.HUD.SetMoney:FireClient(player, playerdata._get(player, "money"))
    return true
end

function attemptEquipmentPurchase(player, equipment)
    if gamedata.status == "inactive" or not gamedata.canBuy then
        return false, "Can't use buy menu at this time."
    end

    local price = options.Enum.EQUIPMENT_COST[equipment]
    if playerdata._get(player, "money") < price then
        return false, "Can't afford equipment."
    end

    local inv = playerdata._get(player, "inventory")

    local shieldToSet = false
    local helmetToSet = false
    local defuserToSet = false

    if equipment == "lightShield" then
        if inv.equipment.shield >= options.Enum.EQUIPMENT_MAX_AMOUNT.lightShield then
            return false, "Light Shield already owned."
        end
        shieldToSet = options.Enum.EQUIPMENT_MAX_AMOUNT.lightShield
    elseif equipment == "heavyShield" then
        if inv.equipment.shield >= options.Enum.EQUIPMENT_MAX_AMOUNT.heavyShield and inv.equipment.helmet then
            return false, "Heavy Shield already owned."
        end
        shieldToSet = options.Enum.EQUIPMENT_MAX_AMOUNT.heavyShield
        helmetToSet = true
    else
        if inv.equipment.defuser then
            return false, "Defuser already owned."
        end
        defuserToSet = true
    end

    if shieldToSet then
        Player:SetShield(player.Character, shieldToSet)
    end
    if helmetToSet then
        Player:SetHelmet(player.Character, true)
    end
    if defuserToSet then
        player.Character:SetAttribute("Defuser", true)
    end

    playerdata._dec(player, "money", price)
    GamemodeEvents.HUD.SetMoney:FireClient(player, playerdata._get(player, "money"))
    return true
end

return BuyMenu
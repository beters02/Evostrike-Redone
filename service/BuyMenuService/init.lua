if game:GetService("RunService"):IsClient() then return require(script:WaitForChild("Client")) end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local WeaponService = require(Framework.Service.WeaponService)
local AbilityService = require(Framework.Service.AbilityService)
local Tables = require(Framework.Module.lib.fc_tables)
local EvoPlayer = require(Framework.Module.EvoPlayer)

local BuyMenuService = {}
local Types = require(script:WaitForChild("Types"))
local Events = script:WaitForChild("Events")
local ServiceCommunicate = Events.ServiceCommunicate

BuyMenuService.Types = Types
BuyMenuService.Events = Events
BuyMenuService._currentgui = script:WaitForChild("BuyMenu")
BuyMenuService._cache = {connections = {}, playerdata = {}}
BuyMenuService._config = {equipBoughtInstant = false, resetBuyMenuOnDeath = false, resetInventoryOnDeath = false, openOnSpawn = false}
BuyMenuService._connections = {}

--@summary Start the BuyMenuService with a Custom BuyMenuGui (Default if unspecified)
function BuyMenuService:Start(buyMenuGui: ScreenGui?, config: table?)
    if buyMenuGui then BuyMenuService._currentgui = buyMenuGui end
    if config then for i, v in pairs(config) do BuyMenuService._config[i] = v end end
    ServiceCommunicate.OnServerInvoke = function(player, action, ...)
        local func = BuyMenuService[action]
        if not func then return error("BuyMenuService" .. tostring(action) .. " does not exist.") end
        return func(player, ...)
    end
    BuyMenuService._connections.playerAdded = Players.PlayerAdded:Connect(PlayerAdded)
    BuyMenuService._connections.playerRemoving = Players.PlayerRemoving:Connect(PlayerRemoving)
    BuyMenuService._connections.playerDied = EvoPlayer.PlayerDied:Connect(PlayerDied)
    InitAllPlayersData()
end

function BuyMenuService:Stop()
    ServiceCommunicate.OnServerInvoke = nil
    BuyMenuService:RemoveBuyMenuMultiple(Players:GetPlayers())
    ClearPlayerData("all")
    for _,v in pairs(BuyMenuService._connections) do
        v:Disconnect()
    end
    table.clear(BuyMenuService._connections)
end

--

function PlayerAdded(player)
    if BuyMenuService._cache.playerdata[player.Name] then return end
    local _pd = Types.PlayerData.new()
    _pd.Connections.CharacterAdded = player.CharacterAdded:Connect(function()
        BuyMenuService:AddBuyMenu(player)
        print("BuyMenuAdded " .. player.Name)
    end)

    BuyMenuService._cache.playerdata[player.Name] = _pd
end

function PlayerRemoving(player)
    BuyMenuService._cache.playerdata[player.Name] = nil
    ClearPlayerData(player)
end

function PlayerDied(player)
    if BuyMenuService._config.resetBuyMenuOnDeath then
        BuyMenuService:RemoveBuyMenu(player)
    end
end

function ClearPlayerData(player: Player | "all")
    local servicePlayerData = BuyMenuService._cache.playerdata
    local playerData = type(player) == "string" and servicePlayerData or {[player.Name] = servicePlayerData[player.Name]}
    for i, v in pairs(playerData) do
        v = v :: Types.BuyMenuPlayerData
        for _, conn in ipairs(v.Connections) do
            conn:Disconnect()
        end
        BuyMenuService._cache.playerdata[i] = nil
    end
end

function InitAllPlayersData(players: table?)
    for _, v in pairs(players or Players:GetPlayers()) do
        if not BuyMenuService._cache.playerdata[v.Name] then
            PlayerAdded(v)
        end
    end
end

--

function BuyMenuService:AddBuyMenu(player, enabled, properties)
    local playerdata = BuyMenuService._cache.playerdata[player.Name]
    enabled = enabled or false

    -- buy menu connection and gui sanity
    if playerdata.BuyMenu then
        playerdata.BuyMenu:Destroy()
        playerdata.BuyMenu = false
    end

    local _buymenu = BuyMenuService._currentgui:Clone()
    _buymenu.ResetOnSpawn = false
    _buymenu.Parent = player.PlayerGui
    _buymenu.Enabled = enabled
    if properties then Tables.combine(_buymenu, properties) end

    playerdata.Connections.BuyMenuWeaponSelected = _buymenu:WaitForChild("WeaponSelected").OnServerEvent:Connect(function(plr, weapon)
        if plr ~= player then return end -- roblox sanity
        BuyMenuService:BuyWeapon(player, weapon)
    end)

    playerdata.Connections.BuyMenuAbilitySelected = _buymenu:WaitForChild("AbilitySelected").OnServerEvent:Connect(function(plr, ability)
        if plr ~= player then return end -- roblox sanity
        BuyMenuService:BuyAbility(player, ability)
    end)

    playerdata.BuyMenu = _buymenu
    BuyMenuService._cache.playerdata[player.Name] = playerdata
end

function BuyMenuService:RemoveBuyMenu(player)
    local playerdata = BuyMenuService._cache.playerdata[player.Name]
    if not playerdata then return end
    if playerdata.BuyMenu then
        playerdata.BuyMenu:Destroy()
        playerdata.BuyMenu = false
    end
    for i, conn in pairs(playerdata.Connections) do
        if string.match(i, "BuyMenu") then
            conn:Disconnect()
            playerdata.Connections[i] = nil
        end
    end
    if BuyMenuService._config.resetInventoryOnDeath then playerdata.Inventory = Types.PlayerInventory.new() end
    BuyMenuService._cache.playerdata[player.Name] = playerdata
end

function BuyMenuService:BuyWeapon(player, weapon)
    local module = WeaponService:GetWeaponModule(weapon)
    if not module then return error("Could not buy " .. tostring(weapon) .. " non-existent weapon.") end
    local slot = require(module).Configuration.inventorySlot
    BuyMenuService._cache.playerdata[player.Name].Inventory.Weapon[slot] = weapon
    if BuyMenuService:GetIsBoughtInstant() then
        WeaponService:AddWeapon(player, weapon)
    end
end

function BuyMenuService:BuyAbility(player, ability)
    local module = AbilityService:GetAbilityModule(ability)
    if not module then return error("Could not buy " .. tostring(ability) .. " non-existent ability.") end
    local slot = require(module).Configuration.inventorySlot
    BuyMenuService._cache.playerdata[player.Name].Inventory.Ability[slot] = ability
    if BuyMenuService:GetIsBoughtInstant() then
        AbilityService:AddAbility(player, ability)
    end
end

function BuyMenuService:GetInventory(player)
    local pd = BuyMenuService._cache.playerdata[player.Name].Inventory
    if not pd then
        local count = 0
        while count < 3 and not pd do
            pd = BuyMenuService._cache.playerdata[player.Name].Inventory
            count += 1
        end
    end
    return pd or false
end

function BuyMenuService:SetInventory(player, inventory)
    local pd = BuyMenuService:GetInventory(player)
    BuyMenuService._cache.playerdata[player.Name].Inventory = inventory
end

--

--[[ GamemodeService -> BuyMenu Utility ]]
function BuyMenuService:GetIsBoughtInstant(variant)
    return BuyMenuService._config.equipBoughtInstant
end

function BuyMenuService:SetIsBoughtInstant(variant)
    BuyMenuService._config.equipBoughtInstant = variant
end

--[[ Buy Menu Extra Utiliy ]]
function BuyMenuService:AddBuyMenuMultiple(players)
    for _, v in ipairs(players) do
        BuyMenuService:AddBuyMenu(v)
    end
end

function BuyMenuService:RemoveBuyMenuMultiple(players)
    for _, v in ipairs(players) do
        BuyMenuService:RemoveBuyMenu(v)
    end
end

return BuyMenuService
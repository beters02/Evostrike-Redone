local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local PlayerData = require(Framework.Module.shared.PlayerData.m_clientPlayerData)
local WeaponModules = ReplicatedStorage:WaitForChild("Services"):WaitForChild("WeaponService"):WaitForChild("Weapon")
local WeaponService = require(Framework.Service.WeaponService)
local RegisteredWeapons = WeaponService:GetRegisteredWeapons()
local RegisteredKnives = WeaponService:GetRegisteredKnives()

local inventory = {}

function inventory:init()
    
end

function inventory:update()
    self:updateData()
end

function inventory:updateData()
    self._currentStoredInventory = PlayerData:Get("inventory.skin")
    self._currentEquippedInventory = PlayerData:Get("inventory.equipped")
    self._currentStoredCaseInventory = PlayerData:Get("inventory.case")
end

-- [[ SKINS ]]

function inventory:skinInit()
    local ignoreWeapons = {}
    for _, v in pairs(self._currentStoredInventory)do
        if v == "*" then
            for _, wep in pairs(RegisteredWeapons) do
                self:initAllWeaponSkinsAsFrames(wep)
            end
            return
        elseif string.match(v, "*") and ignoreWeapons[v] then
            ignoreWeapons[v] = true
            self:initAllWeaponSkinsAsFrames(v)
        else
            self:skinCreateFrame(v)
        end
    end
end

function inventory:skinCreateFrame(skin: string)
    
end

function inventory:initAllWeaponSkinsAsFrames(weapon: string)
    
end

-- [[ CASES ]]

return inventory
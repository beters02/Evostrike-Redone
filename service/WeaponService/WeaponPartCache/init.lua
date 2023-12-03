-- [[ CLIENT MODULE ]]

-- [[ CONFIGURATION ]]
local BULLET_AMOUNT = 100
local BULLET_HOLE_AMOUNT = 100

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Models = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models")

local Bullet = Models:WaitForChild("Bullet")
local BulletHole = Models:WaitForChild("BulletHole")

local Cache = {}
Cache.__index = Cache

function Cache.new(bulletAmount, bulletHoleAmount)
    local self = setmetatable({}, Cache)

    local mainFolder = Instance.new("Folder", ReplicatedStorage)
    mainFolder.Name = "PartCache"
    local bulletFolder = Instance.new("Folder", mainFolder)
    bulletFolder.Name = "Bullets"
    local bulletHoleFolder = Instance.new("Folder", mainFolder)
    bulletHoleFolder.Name = "BulletHoles"

    bulletAmount = bulletAmount or BULLET_AMOUNT
    bulletHoleAmount = bulletHoleAmount or BULLET_HOLE_AMOUNT

    task.spawn(function()
        for _ = 1, bulletAmount do
            Bullet:Clone().Parent = bulletFolder
        end
    
        for _ = 1, bulletHoleAmount do
            local bhc = BulletHole:Clone()
            bhc.Parent = bulletHoleFolder
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = bhc
            weld.Parent = bhc
            weld.Name = "MainWeld"
        end
    end)
    
    self.MainFolder = mainFolder
    self.BulletFolder = bulletFolder
    self.BulletHoleFolder = bulletHoleFolder
    return self
end

function Cache:Bullet()
    local bullet = {instance = self.BulletFolder["Bullet"]}

    function bullet:Destroy()
        bullet.instance.Parent = self.BulletFolder
    end

    return bullet
end

function Cache:BulletHole()
    local bulletHole = {instance = self.BulletHoleFolder["BulletHole"]}

    function bulletHole:Destroy()
        bulletHole.instance.Parent = self.BulletHoleFolder
        bulletHole = nil
    end

    return bulletHole
end

function Cache:Destroy()
    self.MainFolder:Destroy()
    self = nil
end

return Cache
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

-- AbilityService
local AbilityService = require(Framework.Service.AbilityService)
AbilityService:Start()

-- WeaponService
local WeaponService = require(Framework.Service.WeaponService)
WeaponService:Start()

-- GamemodeService
local GamemodeService = require(Framework.Service.GamemodeService)
GamemodeService:Start()

-- Framework Services
for _, v in pairs(ReplicatedStorage:WaitForChild("Services"):GetChildren()) do
    require(v)
end
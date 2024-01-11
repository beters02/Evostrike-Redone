--[[
    WeaponController Client Script.
    To access the Player's weapon controller,
    do local weaponController = require(character.WeaponController.Interface)
]]

local controller = require(game:GetService("ReplicatedStorage").Services.WeaponService.WeaponController).new()
local interface = require(script:WaitForChild("Interface"))
interface.init(controller)
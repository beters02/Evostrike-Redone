local Client = {}
local RemoteEvent = script.Parent.Events.RemoteEvent
local Weapons = script.Parent:WaitForChild("Weapon")

function Client:AddWeapon(player: Player, weapon: string)
    RemoteEvent:FireServer("AddWeapon", weapon)
end

function Client:GetWeaponModule(weapon: string)
    local module = false
    for i, v in pairs(Weapons:GetChildren()) do
        if string.lower(weapon) == string.lower(v.Name) then
            module = v
            break
        end
    end
    return module
end

return Client
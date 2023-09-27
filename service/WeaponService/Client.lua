local Client = {}
local RemoteEvent = script.Parent.Events.RemoteEvent
local RemoteFunction = script.Parent.Events.RemoteFunction
local Weapons = script.Parent:WaitForChild("Weapon")

function Client:AddWeapon(_, weapon: string)
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

function Client:GetRegisteredWeapons()
    return RemoteFunction:InvokeServer("GetRegisteredWeapons")
end

return Client
local Client = {}
local ServiceCommunicate = script.Parent:WaitForChild("Events").ServiceCommunicate

function Client:BuyWeapon(weapon)
    return ServiceCommunicate:InvokeServer("BuyWeapon", weapon)
end

function Client:BuyAbility(ability)
    return ServiceCommunicate:InvokeServer("BuyAbility", ability)
end

return Client
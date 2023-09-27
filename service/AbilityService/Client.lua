local Client = {}
local Remote = script.Parent.Events.RemoteEvent

function Client:AddAbility(_, ability: string)
    Remote:FireServer("AddAbility", ability)
end

function Client:RemoveAbility(_, ability: string)
    Remote:FireServer("RemoveAbility", ability)
end

return Client
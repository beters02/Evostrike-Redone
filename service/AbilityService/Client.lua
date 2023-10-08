local Client = {}
local Remote = script.Parent.Events.RemoteEvent
local RF = script.Parent.Events.RemoteFunction
local Bindable = script.Parent.Events.BindableEvent

function Client:AddAbility(_, ability: string)
    Remote:FireServer("AddAbility", ability)
end

function Client:RemoveAbility(_, ability: string)
    Remote:FireServer("RemoveAbility", ability)
end

function Client:GetAbilityModule(_, ability: string)
    return RF:InvokeServer("GetAbilityModule", ability)
end

function Client:StopAbilityAnimations()
    Bindable:Fire("StopAnimations")
end

return Client
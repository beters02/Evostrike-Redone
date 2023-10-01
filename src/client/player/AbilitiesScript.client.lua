for _, module in pairs(game.ReplicatedStorage.Services.AbilityService.Ability:GetChildren()) do
    require(module)
end

game.ReplicatedStorage.Services.AbilityService.Events.Replicate.OnClientEvent:Connect(function(action, abilityName, origin, direction, thrower)
    if action == "GrenadeFire" then
        require(game.ReplicatedStorage.ability.class[abilityName]):FireGrenade(false, true, origin, direction, thrower)
    end
end)
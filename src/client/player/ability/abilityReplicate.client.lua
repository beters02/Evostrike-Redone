local Replicate = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Grenades"):WaitForChild("Remotes"):WaitForChild("Replicate")

Replicate.OnClientEvent:Connect(function(player, action, abilityName, origin, direction)
    if action == "GrenadeFire" then
        print(abilityName)
        require(game.ReplicatedStorage.ability.class[abilityName]):FireGrenade(false, true, origin, direction)
    end
end)
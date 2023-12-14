local hudevents = game:GetService("ReplicatedStorage").GamemodeEvents.HUD

hudevents.Test.OnServerEvent:Connect(function(player, event, ...)
    hudevents[event]:FireClient(player, ...)
end)
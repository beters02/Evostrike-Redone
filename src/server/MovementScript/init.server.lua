game:GetService("ReplicatedStorage"):WaitForChild("Movement"):WaitForChild("get").OnServerInvoke = function(player)
    return require(game:GetService("ServerScriptService"):WaitForChild("MovementScript"):WaitForChild("config"))
end
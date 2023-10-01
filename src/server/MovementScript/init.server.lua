game:GetService("ReplicatedStorage"):WaitForChild("movement"):WaitForChild("get").OnServerInvoke = function(player)
    return require(game:GetService("ServerScriptService"):WaitForChild("MovementScript"):WaitForChild("config"))
end
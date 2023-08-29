game:GetService("ReplicatedStorage"):WaitForChild("movement"):WaitForChild("get").OnServerInvoke = function(player)
    return require(game:GetService("ServerScriptService"):WaitForChild("movement"):WaitForChild("config").main)
end
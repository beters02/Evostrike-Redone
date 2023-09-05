local botmodule = require(script.Parent:WaitForChild("m_bots"))
local RagdollRE = game:GetService("ReplicatedStorage"):WaitForChild("ragdoll"):WaitForChild("remote"):WaitForChild("sharedRagdollRE")

game:GetService("Players").PlayerAdded:Connect(function(player)
    --[[local bots = botmodule:GetBots()
    print(bots)
    for i, v in pairs(bots) do
        RagdollRE:FireClient(player, "NonPlayerInitRagdoll", v.Character)
    end]]
end)

game:GetService("ReplicatedStorage"):WaitForChild("bots"):WaitForChild("GetBots").OnServerInvoke = function(player)
    return botmodule:GetBots()
end
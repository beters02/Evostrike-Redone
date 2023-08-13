local RunService = game:GetService("RunService")
if RunService:IsServer() then error("m_clientPlayerData: You cannot use this module on the server.") end

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("playerdata"):WaitForChild("remote")

local module = {}

function module.initialize()
    module.stored = module.GetFromStored()
    return module
end

function module.get(optionKey: string, dataKey: string, value: any)
    return module.stored.options[optionKey][dataKey]
end

function module.set(optionKey: string, dataKey: string, value: any)
    module.stored.options[optionKey][dataKey] = value
    return module.stored.options[optionKey][dataKey]
end

--

function module.GetFromStored()
    return Remotes.sharedPlayerDataRF:InvokeServer("Get")
end

function module.UpdateToStoredFromCache()
    return Remotes.sharedPlayerDataRF:InvokeServer("Set", module.stored)
end

return module
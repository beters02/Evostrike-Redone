--[[
    Client Player's HUD Module
    Initialized upon require
    Require from server to access RemoteFunction
]]

local RunService = game:GetService("RunService")
if RunService:IsServer() then
    return require(script:WaitForChild("Server"))
end

local HUD = {}

function HUD:Enable()
    
end

function HUD:Disable()
    
end

return HUD
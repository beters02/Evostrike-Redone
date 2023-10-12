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

local RemoteEvent = script:WaitForChild("Events"):WaitForChild("RemoteEvent")

function HUD.init()
    HUD.player = game.Players.LocalPlayer
    HUD.gui = HUD.player.PlayerGui:WaitForChild("HUD")

    local Component = require(script:WaitForChild("Component"))
    HUD.Components = {}
    for _, v in ipairs(script.Component:GetChildren()) do
        HUD.Components[v.Name] = Component.new(HUD, v)
    end

    RemoteEvent.OnClientEvent = function(action, ...)
        assert(HUD[action], "This action does not exist. " .. tostring(action))
        HUD[action](HUD, ...)
    end
end

function HUD:Enable()
    self.gui.Enabled = true
    HUD:EnableComponents()
end

function HUD:Disable()
    self.gui.Enabled = false
    HUD:DisableComponents()
end

function HUD:EnableComponents()
    for _, v in pairs(HUD.Components) do
        v:Enable()
    end
end

function HUD:DisableComponents()
    for _, v in pairs(HUD.Components) do
        v:Disable()
    end
end

function HUD:EnableComponent(component: string)
    local _comp = self:GetComponent(component)
    assert(_comp, "Could not find component " .. tostring(component))
    _comp:Enable()
end

function HUD:DisableComponent(component: string)
    local _comp = self:GetComponent(component)
    assert(_comp, "Could not find component " .. tostring(component))
    _comp:Disable()
end

function HUD:GetComponent(component: string)
    local v = HUD.Components[component]
    return v or false
end

--@run
HUD.init()

return HUD
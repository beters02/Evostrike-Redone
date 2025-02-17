local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Types = require(ReplicatedStorage.Framework:WaitForChild("Types"))

--[[
    Utility
]]

local function combine(t, t1)
    for i, v in pairs(t1) do
        t[i] = v
    end
    return t
end

--[[
    Type Compiling

    these are named by tree prefix (shared = sh, server = s, client = c)
    following the framework type (FunctionContainer = fc, Class = c, ...)

    ex:
    Shared Function Container = shfc
]]

local typecomp = {}

typecomp.shfc_ = function(key: string, loc)
    key = key:gsub("shfc", "fc")
    loc = loc.Name ~= "ReplicatedStorage" and loc or game:GetService("ReplicatedStorage")
    loc = loc[key]
    return {Access = "Shared", Location = loc} :: Types.FunctionContainer
end

typecomp.sfc_ = function(key, loc)
    key = key:gsub("sfc", "fc")
    loc = loc.Name ~= "ServerScriptService" and loc or game:GetService("ServerScriptService")
    loc = loc[key]
    return {Access = "Server", Location = loc} :: Types.FunctionContainer
end

typecomp.cfc_ = function(key, loc)
    key = key:gsub("sfc", "fc")
    return {Access = "Client", Location = loc} :: Types.FunctionContainer
end

typecomp.shc_ = function(key: string, loc)
    key = key:gsub("shc", "c")
    loc = loc.Name ~= "ReplicatedStorage" and loc or game:GetService("ReplicatedStorage")
    loc = loc[key]
    return {Access = "Shared", Location = loc} :: Types.Class
end

typecomp.shm_ = function(key: string, loc)
    key = key:gsub("shm", "m")
    loc = loc.Name ~= "ReplicatedStorage" and loc or game:GetService("ReplicatedStorage")
    loc = loc[key]
    return {Access = "Shared", Location = loc, Client = function() end} :: Types.Module
end

typecomp.cm_ = function(key: string, loc)
    key = key:gsub("cm", "m")
    loc = loc[key]
    return {Access = "Client", Location = loc, Client = function() end} :: Types.Module
end

typecomp.sm_ = function(key: string, loc)
    key = key:gsub("sm", "m")
    loc = loc.Name ~= "ServerScriptService" and loc or game:GetService("ServerScriptService")
    loc = loc[key]
    return {Access = "Server", Location = loc, Server = function() end} :: Types.Module
end

typecomp.ssm_ = function(key: string, loc)
    key = key:gsub("ssm", "sm")
    loc = loc.Name ~= "ServerScriptService" and loc or game:GetService("ServerScriptService")
    loc = loc[key]
    return {Access = "Server", Location = loc, Server = function() end} :: Types.Module
end

--[[
    Compiling for each tree
]]

local function CompileTree(self, prefix, location, except: table)
    for i, v in pairs(location:GetDescendants()) do
        if location.Name == "ServerScriptService" and (v.Parent.Name == "ability" or v.Parent.Name == "weapon") then continue end

        if v.Parent:IsA("ModuleScript") then continue end
        if not v:IsA("ModuleScript") or not string.match(v.Name, "_") then
            continue
        end

        local _, endi = string.find(v.Name, "_")
        local key = string.sub(v.Name, 1, endi)
        local newPrefix = prefix .. key

        if not typecomp[newPrefix] then warn("Could not find compile function table: " .. newPrefix) end

        local gameObject = typecomp[newPrefix](prefix .. v.Name, v.Parent)
        self[prefix .. v.Name] = gameObject
    end

    return self
end

local function CompileShared()
    local _new = {}
    _new = CompileTree(_new, "sh", ReplicatedStorage)
    return _new
end


local function CompileClient()
    local self = {}
    self.GetCharacterScript = function(character, scriptName)
        local scrip = character:FindFirstChild(scriptName)

        if not scrip then
            for _, charscript in pairs(character:GetChildren()) do
                scrip = charscript:FindFirstChild(scriptName)
                if scrip then break end
            end
        end
        
        if not scrip then return end -- TODO: module not found protocol
        return scrip
    end
    return self
end

local function CompileServer()
    local _new = {}
    _new = CompileTree(_new, "s", game:GetService("ServerScriptService"))
    return _new
end

--[[
    Run Script on Require
]]

local compiled = CompileShared()
if RunService:IsServer() then
    compiled = combine(compiled, CompileServer())
elseif RunService:IsClient() then
    compiled = combine(compiled, CompileClient())
end

return compiled
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Types = require(ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Types"))

local compiler = {}

local parse_translations

--[[
    Utility
]]

local function CloneTable(tab)
    local new = {}
    for i, v in pairs(tab) do
        new[i] = v
    end
    return new
end

local function quickcombine(tab, tab1)
    for i, v in pairs(tab1) do
        if tonumber(i) then table.insert(tab, v) else tab[i] = v end
    end
    return tab
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

--[[
    Compiling for each tree
]]

local function CompileTree(self, prefix, location, except: table)
    for i, v in pairs(location:GetDescendants()) do

        if v.Parent:IsA("ModuleScript") then continue end
        if not v:IsA("ModuleScript") or not string.match(v.Name, "_") then
            continue
        end

        local _, endi = string.find(v.Name, "_")
        local key = string.sub(v.Name, 1, endi)
        local newPrefix = prefix .. key

        local gameObject = typecomp[newPrefix](prefix .. v.Name, v.Parent)
        self[prefix .. v.Name] = gameObject
    end

    return self
end

function compiler:CompileShared()
    self = CompileTree(self, "sh", ReplicatedStorage)
    return self
end

function compiler:CompileServer()
    self.Weapon = smf_Weapon(self)
    self.Ability = smf_Ability(self)
    return self
end

function compiler:CompileClient()
    self.GetCharacterScript = function(character, scriptName)
        return character:FindFirstDescendant(scriptName)
    end
    return self
end

-- CompileCharacter will create connections to
-- automatically compile any character modules.
function compiler:CompileCharacter(player)
end

--[[
    Hard-Coded Compile Functions
]]

function smf_Weapon(self)
    local _mWeaponFold = game:GetService("ServerScriptService"):WaitForChild("weapon")
    local _loc = _mWeaponFold.pm_main
    local _mWeapon: Types.PlayerModule = {Access = "Server", Location = _loc, Server = _mWeaponFold.mss_main, Client = function() end}
    return _mWeapon
end

function smf_Ability(self)
    local _mAbilityFold = game:GetService("ServerScriptService"):WaitForChild("ability")
    local _loc = _mAbilityFold.pm_main
    local _mAbility: Types.PlayerModule = {Access = "Server", Location = _loc, Server = _mAbilityFold.mss_main, Client = function() end}
    return _mAbility
end

return compiler
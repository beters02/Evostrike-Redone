--[[

    @summary

    This module Initializes the Framework for the game.
    Types and Game Scopes (Client, Server, Shared) are included.



    There are multiple ways to grab a Module with this framework.

    -- The recommended way
    -- This way will make Intellisense work on VS Code without having to call require()
    local module = require(Framework[ModuleName] or Framework.__index[ModuleName])
    

    -- Other ways:

    local module = Framework[ModuleName].Module

    or

    lcoal module = require(Framework[ModuleName].Location)





    Note:
    A lot of things are hardcoded because of Intellisense
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FrameworkLocation = ReplicatedStorage:WaitForChild("Framework")
local Compiler = require(FrameworkLocation:WaitForChild("Compiler"))
local Types = require(FrameworkLocation:WaitForChild("Types"))

local Framework = {}
Framework._types = Types

-- [[ Compile Modules ]]
-- it looks like having a compiler makes intellisense not work

local function quickGetClient(player)
    if not player then return end
end

local function compileAbility()
    local _mAbilityFold = game:GetService("ServerScriptService"):WaitForChild("ability")
    local _loc = _mAbilityFold.pm_main
    local _mAbility: Types.PlayerModule = {Access = "Server", Location = _loc, Server = _mAbilityFold.mss_main, Client = quickGetClient, Module = require(_loc)}
    return _mAbility
end

local function compileWeapon()
    local _mWeaponFold = game:GetService("ServerScriptService"):WaitForChild("weapon")
    local _loc = _mWeaponFold.pm_main
    local _mWeapon: Types.PlayerModule = {Access = "Server", Location = _loc, Server = _mWeaponFold.mss_main, Client = quickGetClient, Module = require(_loc)}
    return _mWeapon
end

local compile = {
    shfc_ = function(key: string)
        key = key:gsub("shfc", "fc")
        local n: Types.FunctionContainer = {Access = "Shared", Location = game:GetService("ReplicatedStorage")[key], Module = require(game:GetService("ReplicatedStorage")[key])}
        Framework[key] = n
        return n
    end,
    sfc_ = function(key)
        key = key:gsub("sfc", "fc")
        local n: Types.FunctionContainer = {Access = "Server", Location = game:GetService("ServerScriptService")[key], Module = require(game:GetService("ServerScriptService")[key])}
        Framework[key] = n
        return n
    end,
    cfc_ = function(key)
        key = key:gsub("sfc", "fc")
        local n: Types.FunctionContainer = {Access = "Client", Location = game:GetService("ServerScriptService")[key], Module = require(game:GetService("ServerScriptService")[key])}
        Framework[key] = n
        return n
    end,

    shc_ = function(key: string)
        key = key:gsub("shc", "c")
        local req = require(game:GetService("ReplicatedStorage")[key])
        local n: Types.Class = {Access = "Shared", Location = game:GetService("ReplicatedStorage")[key], Module = req, New = req.new}
        Framework[key] = n
        return n
    end,

    shm_ = function(key: string)
        key = key:gsub("shm", "m")
        local req = require(game:GetService("ReplicatedStorage")[key])
        local n: Types.Module = {Access = "Shared", Location = game:GetService("ReplicatedStorage")[key], Client = quickGetClient}
        Framework[key] = n
        return n
    end
}

if RunService:IsServer() then
    Framework.Weapon = compileWeapon()
    Framework.Ability = compileAbility()
end

-- Indexing for non pre-compiled modules
Framework.__index = function(table, key: string)
    local _, ciE = key:find("_")
    local compileIndex = key:sub(1, ciE)
    return compile[compileIndex](key)
end


return Framework
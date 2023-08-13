--[[
    FRAMEWORK INFO

    - Modules that are children of modules will not be compiled since those are not global access modules.
    - To grab a module child, call Framework[parentModuleNameWithPrefix].Location[moduleNameWithPrefix]

    - Modules that do not have the FrameworkType prefix will not be compiled.

    - How to grab a module (global access):
    
    1. Require the Framework in the current script.
    2. Get the module name, with the tree prefix added. (shared = sh, server = s, client = c)
    3. Require Framework[moduleNameWithPrefix].Location

    ex: Strings
    local strings: FunctionContainer = Framework.shfc_strings -- Just calling the module name will return an object of it's FrameworkType
    strings = require(strings.Location)

]]

local function combine(t, t1)
    for i, v in pairs(t1) do
        t[i] = v
    end
    return t
end

--[[
    @summary

    This module Initializes the Framework for the game.
    Types and Game Scopes (Client, Server, Shared) are included.
]]

local RunService = game:GetService("RunService")
local FrameworkLocation = game:GetService("ReplicatedStorage"):WaitForChild("Framework")
local Types = require(FrameworkLocation:WaitForChild("Types"))

local Framework = {}
Framework._types = Types

-- new compiler test
local Compiled = require(FrameworkLocation:WaitForChild("CompilerWithGrabTest"))
Framework = combine(Framework, Compiled)

--[[
-- Compile Shared for Client and Server
Framework = Compiler.CompileShared(Framework)

-- Compile Server for Server
if RunService:IsServer() then
    Framework = Compiler.CompileServer(Framework)
end

-- Indexing for non pre-compiled modules
Framework.__index = function(table, key: string)
end
]]

return Framework
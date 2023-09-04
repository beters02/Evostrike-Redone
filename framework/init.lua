--[[
    ==== FRAMEWORK INFO ====

    - Almost all modules are organized by FrameworkType, using a prefix to represent the type.

    Example:
    fc_strings = FunctionContainer strings
    m_states = Module states
    c_playerActions = Class playerActions

    - Some modules are classes but are not labeled as so, because they dont carry the rules of a class.
    - Modules that are children of modules will not be compiled since those are not global access modules.
    - Modules that do not have the FrameworkType prefix will not be compiled.
    See framework/Types


    ---------------------------------------------
    

    ==== TUTORIALS: ====

    === GRAB SHARED LIB MODULE PREFERRED WAY === (Framework.Module.lib.examplelib)

    1. Call require(Framework.Module.lib.exampleLib)

    ex: Strings
    local strings = require(Framework.Module.lib.fc_strings)

    ===


    === GRAB ANY MODULE LONG WAY WITH METADATA === (Framework.Module.shared.exampleModuleFolder.exampleModule)
    treeLocation: "shared" | "server"
    rbxLocation: string -- the location string of the module within the tree location

    1. Call require(Framework.Module.treeLocation[rbxLocation...])

    ex: ClientPlayerData
    local clientPlayerData = require(Framework.Module.shared.playerdata.m_clientPlayerData)

    ===


    === GRAB ANY MODULE SHORT WAY WITHOUT METADATA === (Framework.frtype_module.Location)
    frtype: FrameworkType (ex- fc: FunctionContainer)
    
    1. Call require(Framework.frtype_module.Location)

    ex: Strings
    location strings = require(Framework.shfc_strings.Location)

    ===

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

-- Compile Functions
Framework = combine(Framework, require(FrameworkLocation:WaitForChild("Compiler")))

-- Compile Explicit Access Functions
Framework.Module = setmetatable(require(FrameworkLocation.ExplicitCompiler), Framework)

return Framework
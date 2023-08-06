--[[    Module
            - @title:        - Framework

            - @summary:      - Easily access folders for variable creation
                             - I was getting sick of :WaitForChild nonsense

            -
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = {}
Framework.__index = Framework
Framework.Location = ReplicatedStorage.Framework
Framework.Types = require(Framework.Location.Types) -- Dipping my toes into types

-- Init Types and Functions modules
local Types = Framework.Types
local Functions = require(Framework.Location.Functions)

local function CreateGameFolder(location: Folder)
    local gf = setmetatable({}, {
		__index = Functions -- You can either set __index or don't but must return a table with assigned type
	}) :: Types.GameFolder --Require for the Script to autofill framework functions
    
    gf.FolderLocation = location
    return gf
end

function Framework.Init()
    local new = {}

    -- we brute force code all of this for autofill
    -- i just spent 5.5 hours trying to figure out auto type fill with for loops but nothing :/

    if game:GetService("RunService"):IsServer() then
        local ServerScriptService = CreateGameFolder(game:GetService("ServerScriptService"))
        ServerScriptService.Modules = game:GetService("ServerScriptService").Modules
        new.ServerScriptService = ServerScriptService
    end

    local ReplicatedStorage = CreateGameFolder(game:GetService("ReplicatedStorage"))
    ReplicatedStorage.Libraries = game:GetService("ReplicatedStorage"):WaitForChild("Scripts"):WaitForChild("Libraries")
    ReplicatedStorage.Objects = game:GetService("ReplicatedStorage"):WaitForChild("Objects")
    ReplicatedStorage.Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
    ReplicatedStorage.Functions = game:GetService("ReplicatedStorage"):WaitForChild("Scripts").Functions
    ReplicatedStorage.Modules = game:GetService("ReplicatedStorage").Scripts.Modules

    new.ReplicatedStorage = ReplicatedStorage
    return new
end

return Framework.Init()
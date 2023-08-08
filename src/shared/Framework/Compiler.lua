--[[

    THIS MODULE IS TEMPORARILY DISABLED WHILE I FIGURE OUT WHY IT BREAKS INTELLISENSE

]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

--[[
    Prefix Translations
]]

parse_translations = {
    M_ = "Module",
    PM_ = "PlayerModule",
    C_ = "Class",
    F_ = "Function",
    FC_ = "FunctionContainer",
    MSS_ = "Module Server Script",
    MCS_ = "Module Client Script"
}

--[[
    Compiling for each tree
]]

-- again, for intellisense
-- this shit is going to have to be hardcoded

function compiler:CompileShared()
end

function compiler:CompileServer()
end

function compiler:CompileClient()
end

-- Lib is a hard ModuleScript File access that does not do require()
function compiler:CompileLib()
end

--[[
    Hard-Coded Compile Functions
]]

-- smf = server module function
-- shmf = shared module function
-- cmf = client module function

function smf_Weapon(self)
end

function smf_Ability(self)
end

return compiler
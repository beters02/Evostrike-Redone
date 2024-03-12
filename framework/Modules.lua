--[[== grab modules with metadata ==]]

local s = game:GetService("ServerScriptService")
local sh = game:GetService("ReplicatedStorage")

local compiler = {}

function compiler.compileTreeFolders()
    -- beautiful type checking
    setmetatable(compiler, {__index = sh.Modules})
    compiler.server = s
    compiler.shared = sh
    compiler.lib = sh.lib

    for _, v in pairs(sh:WaitForChild("Modules"):GetChildren()) do
        compiler[v.Name] = v
    end
end

compiler.compileTreeFolders()

return compiler
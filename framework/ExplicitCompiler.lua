--[[== grab modules with metadata ==]]
local compiler = {}

local s = game:GetService("ServerScriptService")
local sh = game:GetService("ReplicatedStorage")

-- beautiful type checking
setmetatable(compiler, {__index = sh.Modules})
compiler.server = s
compiler.shared = sh
compiler.lib = sh.lib

for i, v in pairs(sh:WaitForChild("Modules"):GetChildren()) do
    compiler[v.Name] = v
end

return compiler
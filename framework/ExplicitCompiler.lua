--[[== grab modules with metadata ==]]

local s = game:GetService("ServerScriptService")
local sh = game:GetService("ReplicatedStorage")

return {
    lib = sh:WaitForChild("lib"),
    server = s,
    shared = sh
}
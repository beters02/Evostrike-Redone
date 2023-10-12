--[[
    This Service acts less like a Service and more like an Interface,
    as it directly links to GameScript and relies on that script to process any functionality outside of the Gamemode Script.
]]

type GamemodeObject = {Name: string, Script: Script, Interface: any}

local GamemodeService = {}
GamemodeService.Location = script
GamemodeService.DefaultGamemode = "Deathmatch"

function GamemodeService:GetGamemodeScript(gamemode: string)
    return GamemodeService.Location.GamemodeScripts:FindFirstChild(gamemode)
end

return GamemodeService
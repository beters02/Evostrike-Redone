local Types = require(script.Parent:WaitForChild("Types"))
type SCommand = Types.SCommand

local Commands = {}

Commands.help = {
    name = "help",
    vars = {},

    callback = function(console: Types.CConsole)
        console:PrintTable(console.commands, false, function(i, v)
            console:Print(i)
        end)
    end
}

return Commands
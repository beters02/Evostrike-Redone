local Types = require(script.Parent:WaitForChild("Types"))
type SCommand = Types.SCommand

local Commands = {}

Commands.printMyName = {
    name = "printMyName",
    vars = {
        first_name = {vartype = "string", required = true, index = 1},
        last_name = {vartype = "string", required = false, index = 2}
    },

    callback = function(console: Types.CConsole, first_name: string, last_name: string?)
        local varSuccess = console.testVar(console, "printMyName", table.pack(first_name, last_name))
        if not varSuccess then return end
        local name = first_name
        if last_name then
            name = first_name .. " " .. last_name
        end
        console:Print(name)
    end,

    server_callback = false,
}

return Commands
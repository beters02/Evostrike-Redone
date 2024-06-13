local Types = require(script.Parent:WaitForChild("Types"))
local Animations = require(script.Parent:WaitForChild("Animations"))
local Objects = require(script.Parent:WaitForChild("Objects"))
local Shared = {}

Shared.DefConsoleCfg = {
    blur_when_opened = true,
    blur_max_size = 24,
    blur_fade_in_length = 0.4,
    blur_fade_out_length = 0.6,
    console_fade_in_length = 0.3,
    console_fade_out_length = 0.4,
    open_key = "Backquote",
    color_print = Color3.fromRGB(255,255,255),
    color_warn = Color3.fromRGB(255, 255, 0),
    color_error = Color3.fromRGB(200, 0, 0),
    print_line_index = false,
    auto_fill_item_color_default = Color3.fromRGB(29, 29, 29),
    auto_fill_item_color_selected = Color3.fromRGB(80, 80, 80)
} :: Types.ConsoleCfg

function Shared.println(console: Types.CConsole, msg: string, color: Color3?, cancelLineBreak: boolean?)
    color = color or Color3.new(1,1,1)
    console.lineIndex += 1

    local item = Objects.newTextLine(console, msg, color)
    Animations.initTextItemTween(console, item)

    if not cancelLineBreak then
        Shared.println(console, "", false, true)
    end

    return item
end

return Shared
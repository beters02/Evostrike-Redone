local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script.Parent:WaitForChild("Types"))
local Framework = require(script.Parent:WaitForChild("ConsoleFramework"))
local Connections = Framework.Connections
local AutoFill = require(script.Parent:WaitForChild("AutoFill"))
local Shared = require(script.Parent:WaitForChild("Shared"))

local Typing = {}

function Typing.connectTyping(console: Types.CConsole, connect: boolean)
    Connections.Disconnect(console.conn.Typing)

    if connect then
        console.conn.Typing = UserInputService.InputBegan:Connect(function(input, gp)
            Typing.processTypingInput(console, input, gp)
        end)
        return
    end
end

function Typing.processTypingInput(console, input, gp)

    if not console.opened then
        console.tb:ReleaseFocus()
        return
    end

    if (not gp) and (not console.tb:IsFocused()) then
        console.tb:CaptureFocus()
    end

    if not input.KeyCode then
        return
    end

    if input.KeyCode == Enum.KeyCode.Up then
        AutoFill.cursorUp()
        return
    end

    if input.KeyCode == Enum.KeyCode.Down then
        AutoFill.cursorDown()
        return
    end

    if input.KeyCode == Enum.KeyCode.Return then
        console:Return()
        return
    end

    if input.KeyCode == Enum.KeyCode.Tab then
        local autoFillCmd = AutoFill.tab()
        if autoFillCmd then
            console:SetText(autoFillCmd)
            AutoFill.finish()
            task.wait()
            console:SetText(console:GetText():gsub('\t', ''))
            console.tb.CursorPosition = string.len(console:GetText()) + 1
        end
    end

    task.wait()
    AutoFill.updateResults(console)
end

return Typing
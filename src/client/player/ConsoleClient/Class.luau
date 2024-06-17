local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Types = require(script.Parent:WaitForChild("Types"))
local Animations = require(script.Parent:WaitForChild("Animations"))
local Commands = require(script.Parent:WaitForChild("Commands"))
local Typing = require(script.Parent:WaitForChild("Typing"))
local Shared = require(script.Parent:WaitForChild("Shared"))
local AutoFill = require(script.Parent:WaitForChild("AutoFill"))

local Framework = require(script.Parent:WaitForChild("ConsoleFramework"))
local Tables = Framework.Tables
local Strings = Framework.Strings

local println = Shared.println
local DefConsoleCfg = Shared.DefConsoleCfg

local Console = {}
Console.__index = Console

function Console.new(gui, cfg) : Types.CConsole
    cfg = cfg or {}
    cfg = Tables.Inherit(DefConsoleCfg, cfg) :: Types.ConsoleCfg

    local self: Types.CConsole = {}
    self.player = Players.LocalPlayer
    self.cfg = cfg
    self.lineIndex = 0
    self.lastText = false
    self.savedCommands = {}
    self.opened = false

    self.gui = gui
    self.tb = self.gui.MainFrame.InsertTextFrame.TextBox :: TextBox
    self.tb.ClearTextOnFocus = false
    self.autofr = self.gui.MainFrame.AutoFillFrame :: Frame
    self.gui.Enabled = false
    self.gui.Parent = self.player.PlayerGui

    self.conn = {
        OpenInput = UserInputService.InputBegan:Connect(function(input, gp)
            if input.KeyCode == Enum.KeyCode[cfg.open_key] then
                local func = self.opened and self.Close or self.Open
                func(self)
                task.wait()
                self:SetText(self:GetText():gsub("`", ""))
                return
            end
        end)
    }

    self = setmetatable(self, Console) :: Types.CConsole

    local adminCommandModule = ReplicatedStorage.ConsoleEvents.RemoteFunction:InvokeServer("Init")
    print(adminCommandModule)
    if adminCommandModule then
        for i, v in pairs(require(adminCommandModule)) do
            Commands[i] = v
        end
    end

    Animations.initOpenTweens(self)
    AutoFill.init(self)

    self:Open()
    self:Close()

    self.commands = Commands
    return self
end

function Console:Open()
    self.opened = true
    Typing.connectTyping(self, true)
    self.tb:CaptureFocus()
    self.gui.Enabled = true
    Animations.playOpenTweens(self, true)
end

function Console:Close()
    self.opened = false
    self.tb:ReleaseFocus()
    Animations.playOpenTweens(self, false)
    task.delay(self.cfg.console_fade_out_length, function()
        if not self.opened then
            self.gui.Enabled = false
            Typing.connectTyping(self, false)
            self.tb:ReleaseFocus()
        end
    end)
end

function Console:Print(msg, cancelLineBreak)
    println(self, msg, self.cfg.color_print, cancelLineBreak)
end

function Console:Error(msg, cancelLineBreak)
    println(self, msg, self.cfg.color_error, cancelLineBreak)
end

function Console:Warn(msg, cancelLineBreak)
    println(self, msg, self.cfg.color_warn, cancelLineBreak)
end

function Console:PrintTable(t, color, callback)
    color = color or self.cfg.color_print
    callback = callback or function(i, v)
        println(self, "[ " .. tostring(i) .. " : " .. tostring(v) .. " ]", color, true)
    end
    Tables.PrintTable(t, false, callback)
    println(self, "", false, true)
end

-- Get the currently typed text from console
function Console:GetText()
    return self.gui.MainFrame.InsertTextFrame.TextBox.Text
end

function Console:SetText(txt)
    self.gui.MainFrame.InsertTextFrame.TextBox.Text = txt
end

function Console:Return(fullCommand: string?)

    local autoFillCmd = AutoFill.checkSelected()
    if autoFillCmd then
        self:SetText(autoFillCmd)
        AutoFill.finish()
        return
    end

    fullCommand = fullCommand or self:GetText()
    self.gui.MainFrame.InsertTextFrame.TextBox.Text = ""
    self.lastText = false
    self:Print(self.player.Name .. ": " .. fullCommand, true)

    local words = Strings.ToWordsArray(fullCommand)
    local command = words[1]
    local args = {}
    for i = 2, #words do
        args[i-1] = words[i]
    end

    if not Commands[command] then
        local errorMsg = Types.secreterr._supplyErrorMessageFromWordsArr(words, "Command '" .. tostring(command) .. "' does not exist.")
        self:Error(errorMsg)
        return
    end

    Commands[command].callback(self, table.unpack(args))
    AutoFill.finish()
end

local function clone(t)
    local n = {}
    for i, v in pairs(t) do
        n[i] = type(v) == "table" and clone(v) or v
    end
    return n
end

local function getCommandUsage(command: Types.SCommand)
    local str = "' " .. command.name
    for i, v in pairs(command.vars) do
        local vt = v.vartype
        if not v.required then
            vt = vt .. "?"
        end
        str = str .. " {" .. i .. ": " .. vt .. "}"
    end
    return str .. " '"
end

function Console:testVar(command: string, args: any) -- args is a packed table of the provided arguments
    local console = self
    local scommand = Commands[command] or console.commands[command]
    local vartab = clone(scommand.vars)
    local missing = {}

    for i, v in pairs(vartab) do
        if not args or (v.required and not args[v.index]) then
            local varobj = clone(v)
            varobj.name = i
            table.insert(missing, varobj)
        end
    end

    if #missing > 0 then
        console:Error("Command " .. tostring(scommand.name) .. " failed!", true)
        console:Error("Usage: " .. getCommandUsage(scommand), true)
        console:Error("Missing: ", true)
        console:PrintTable(missing, false, function(_, v)
            console:Error("- ["..v.name..": "..v.vartype.."]")
        end)
        return false
    end

    return true
end

return Console
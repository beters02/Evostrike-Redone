local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local EvoConsole = Framework.Module.EvoConsole
local UserInputService = game:GetService("UserInputService")
local Types = require(EvoConsole.Types)
local Tables = require(EvoConsole.Tables)
local Configuration = require(EvoConsole.Configuration)
local Events = script.Parent.Events
local GameService = require(Framework.Service.GameService)
local Strings = require(Framework.Module.lib.fc_strings)

local States = require(Framework.Module.States)
local UIState = States:Get("UI")

local class = {}
class.__index = class

-- Create
function class.new(Console, player)
    local self = setmetatable({}, class)

    -- get all command modules w/ access & create GUI via server
    local gui, commandModules = Console:ClientToServer(player, "instantiateConsole")

    -- compile commands
    self.Commands = {}
    self.ParsedCommands = {}
    for _, v in pairs(commandModules) do
        self.Commands = Tables.merge(self.Commands, require(v))
    end

    -- convert objects into object of Console type
    local console: Types.Console = {
        UI = gui,
        MainFrame = gui.MainFrame,

        Open = self.Open,
        Close = self.Close,

        Toggle = function()
            if gui.Enabled then self:Close() else self:Open() end
        end,

        IsOpen = function()
            return gui.Enabled
        end
    }

    self.player = player
    self.console = console
    self.returnLines = {} -- store all currently visible return lines for later access

    self.enterBox = self.console.UI.MainFrame.TextEnterFrame.TextEnterLine

    self:Connect()

    return console
end

-- Open the console
function class:Open()
    self:ConnectCommandRegister()
    UIState:addOpenUI("Console", self.console.UI, true)
    UIState:setIsTyping(true)
    self.player:SetAttribute("Typing", true)
    self.console.UI.MainFrame.TextReturnFrame.CanvasPosition = Vector2.new(0, self.console.UI.MainFrame.TextReturnFrame.AbsoluteCanvasSize.Y)
    self.console.UI.Enabled = true
    self.enterBox:CaptureFocus()
end

-- Close the console
function class:Close()
    self:DisconnectCommandRegister()
    self.console.UI.Enabled = false
    self.player:SetAttribute("Typing", false)
    UIState:removeOpenUI("Console")
    UIState:setIsTyping(false)
end

-- Enter the current text box text as a command
function class:Enter()
    local stringToEnter = self.enterBox.Text
	
	-- get command/args from string
	local split = {}
	for word in string.gmatch(stringToEnter, "%S+") do
		table.insert(split, word)
	end
	
	-- clear text
    self.enterBox.Text = ""
    self.enterBox:CaptureFocus()

    -- attempt do command
	return _doCommand(self, split)
end

function class:Print(msg: string) return _printMsg(self, msg, "message") end
function class:Warn(msg: string) return _printMsg(self, msg, "warn") end
function class:Error(msg: string) return _printMsg(self, msg, "error") end

--

function class:Connect()
    self.connections = {}
    self.connections.input = UserInputService.InputBegan:Connect(function(input, gp)
        --if gp then return end
        if input.KeyCode == Enum.KeyCode.F10 then
            self.console.Toggle()
        end
    end)
end

function class:Disconnect()
    self.connections.input:Disconnect()
end

function class:ConnectCommandRegister()
    self.connections.command = UserInputService.InputBegan:Connect(function(input, gp)
        --if gp then return end
        if input.KeyCode == Enum.KeyCode.Return then
            self:Enter()
        end
    end)
end

function class:DisconnectCommandRegister()
    self.connections.command:Disconnect()
end

--

local colors = {
    message = Configuration.msgColor,
    ["error"] = Configuration.errorColor,
    ["warn"] = Configuration.warnColor
}

function _printMsg(self, msg: string, msgType: Types.ReturnMessageType|nil)
    if not msgType then msgType = "message" :: Types.ReturnMessageType end

    local txtReturnFrame = self.console.UI.MainFrame.TextReturnFrame
    local lineTemplate = txtReturnFrame.Line

    -- check if max lines have been reached
    local maxLines = txtReturnFrame.CanvasSize.Y.Scale / lineTemplate.Size.Y.Scale
    if #self.returnLines >= maxLines then
        txtReturnFrame.CanvasSize.Y.Scale = UDim2.new(txtReturnFrame.CanvasSize.X.Scale, txtReturnFrame.CanvasSize.Y.Scale + lineTemplate.Size.Y.Scale)
    end

    if lineTemplate.Position.Y.Scale > txtReturnFrame.CanvasSize.Y.Scale then
        local diff = lineTemplate.Position.Y.Scale - txtReturnFrame.CanvasSize.Y.Scale
        txtReturnFrame.CanvasSize = UDim2.fromScale(txtReturnFrame.CanvasSize.X.Scale, txtReturnFrame.CanvasSize.Y.Scale + diff)
    end

    -- remove default text if necessary
    if #self.returnLines == 0 then
        lineTemplate.Visible = false
    else
        -- shift the text index number up
        for i, v in pairs(self.returnLines) do

            -- is this nice and fun to look at?
            local pref = tonumber(v.Text:sub(1, 2)) + 1 > 9 and "" or "0"
            v.Text = pref .. tostring(tonumber(v.Text:sub(1, 2)) + 1) .. ": " .. v.Text:sub(5, v.Text:len())
        end
    end

    local line = lineTemplate:Clone() :: TextLabel -- create line ui
    line.Name = tostring(#self.returnLines + 1 .. ": " .. line.Name)

    -- set color
    line.TextColor3 = colors[msgType]

    -- get line count and set message
    line.Text = "01: " .. msg

    -- set line position
    if #self.returnLines ~= 0 then
        line.Position = UDim2.fromScale(line.Position.X.Scale, line.Position.Y.Scale - line.Size.Y.Scale)
    end

    line.Parent = lineTemplate.Parent
    line.Visible = true

    table.insert(self.returnLines, line)
    return true
end

function _doServerVarCommand(self, commandSplit)
    local key = string.gsub(commandSplit[1], "sv_", "")
    local value = commandSplit[2]
    print(key, value)
    local success, err = GameService:ChangeServerVar(key, value)
    if not success then
        return self:Error(err)
    end
    return self:Print(commandSplit[1] .. " " .. success)
end

function _doCommand(self, commandSplit: table)

    -- verify command string was found
    if not commandSplit or not commandSplit[1] then -- split[1] == command
        return self:Error("Could not get command from string")
	end

    if string.find(commandSplit[1], "sv_") then
        return _doServerVarCommand(self, commandSplit)
    end
	
	-- locate command from Commands
	local commandTable = self.Commands[commandSplit[1]] or self.Commands[Strings.firstToUpper(commandSplit[1])]

    -- cant find command
	if not commandTable then
        return self:Error("Could not find command " .. commandSplit[1])
	end

	-- remove action string to single out and send arguments
    table.remove(commandSplit, 1)

    -- verify via server remote
    local canPerformCommand = Events.VerifyCommandEvent:InvokeServer(table.unpack(commandSplit))
    if not canPerformCommand then
        return self:Error("Must have cheats enabled on the server to use this command.")
    end
	
    -- function
	return commandTable.Function(self, self.player, table.unpack(commandSplit))
end

return class
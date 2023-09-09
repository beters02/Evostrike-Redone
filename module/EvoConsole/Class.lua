local EvoConsole = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("EvoConsole")
local UserInputService = game:GetService("UserInputService")
local Types = require(EvoConsole.Types)
local Tables = require(EvoConsole.Tables)
local Configuration = require(EvoConsole.Configuration)

local States = require(game:GetService("ReplicatedStorage"):WaitForChild("states"):WaitForChild("m_states"))

local class = {}
class.__index = class

-- Create
function class.new(Console, player)
    local self = setmetatable({}, class)

    -- get all command modules w/ access & create GUI via server
    local gui, commandModules = Console:ClientToServer(player, "instantiateConsole")

    -- compile command modules
    self.Commands = {}
    for i, v in pairs(commandModules) do
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

    --UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    --UserInputService.MouseIconEnabled = true
    States.State("UI"):addOpenUI("Console", self.console.UI, true)

    self.console.UI.MainFrame.TextReturnFrame.CanvasPosition = Configuration.canvasPositionStart
    self.console.UI.Enabled = true

    self.player:SetAttribute("Typing", true)
    self.enterBox:CaptureFocus()
end

-- Close the console
function class:Close()
    self:DisconnectCommandRegister()

    --UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    --UserInputService.MouseIconEnabled = false
    States.State("UI"):removeOpenUI("Console")

    self.console.UI.Enabled = false
    self.player:SetAttribute("Typing", false)
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

    local lineTemplate = self.console.UI.MainFrame.TextReturnFrame.Line

    -- check if max lines have been reached
    if lineTemplate.Position.Y.Scale - lineTemplate.Size.Y.Scale < 0 then
        self.returnLines[#self.returnLines]:Destroy() -- destroy last line
        table.remove(self.returnLines, #self.returnLines)
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

function _doCommand(self, commandSplit: table)

    -- verify command string was found
    if not commandSplit or not commandSplit[1] then -- split[1] == command
        return self:Error("Could not get command from string")
	end
	
	-- locate command from Commands
	local commandTable = false
	for i, v in pairs(self.Commands) do
		if string.lower(i) == string.lower(commandSplit[1]) and v.Function then
			commandTable = v
			break
		end
	end
	
	-- cant find command
	if not commandTable then
        return self:Error("Could not find command " .. commandSplit[1])
	end
	
	-- remove action string to single out and send arguments
    table.remove(commandSplit, 1)
	
    -- function
	return commandTable.Function(self, self.player, table.unpack(commandSplit))
end

return class
local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

local UserInputService = game:GetService("UserInputService")
local ConsoleGui = player.PlayerGui:WaitForChild("Console")
local TextBox = ConsoleGui:WaitForChild("EnterTextFrame"):WaitForChild("TextBox")
local CloseButton = ConsoleGui:WaitForChild("CloseButton")
local CommandRemoteFunction = game:GetService("ReplicatedStorage"):WaitForChild("console"):WaitForChild("remotes"):WaitForChild("CommandFunction")

local defaultOpenKeyCode = Enum.KeyCode["F10"] -- this can be changed as needed
local connections = {}

-- Init Player Commands & Console Module

local CommandsTable = CommandRemoteFunction:InvokeServer("InitCommandsModule")
local ConsoleModuleLocation = script.Parent:WaitForChild("m_console")
local ConsoleModule = require(ConsoleModuleLocation)
CommandsTable = ConsoleModule.Init(CommandsTable)

local ClearEvent = CommandsTable.GeneralModuleLocation.events.clear
local CloseEvent = CommandsTable.GeneralModuleLocation.events.close

--

function Open()
	ConsoleGui.Enabled = true
	ConnectCommandConnections()
	TextBox:CaptureFocus()
end

function Close()
	ConsoleGui.Enabled = false
	DisconnectCommandConnections()
	player:SetAttribute("Typing", false)
	TextBox:ReleaseFocus()
end

function ConnectCommandConnections()
	table.insert(connections, ClearEvent.Event:Connect(function()
		ConsoleModule.Clear()
	end))
	table.insert(connections, CloseEvent.Event:Connect(function()
		Close()
	end))
	table.insert(connections, CloseButton.MouseButton1Click:Connect(function()
		Close()
	end))
end

function DisconnectCommandConnections()
	for i, v in pairs(connections) do
		v:Disconnect()
	end
end


--[[
	Logging from Roblox Console
]]
--[[LogService.MessageOut:Connect(function(msg, msgType)
	ConsoleModule.Return(msg, msgType == Enum.MessageType.MessageWarning, msgType == Enum.MessageType.MessageError)
end)]]


--[[
	Inputs for Open, Close and Typing
]]
UserInputService.InputBegan:Connect(function(input)

	-- open/close
	if input.KeyCode == defaultOpenKeyCode then
		if not ConsoleGui.Enabled then
			Open()
		elseif ConsoleGui.Enabled then
			Close()
		end
		return
	end

	if not ConsoleGui.Enabled then return end

	-- typing
	if input.KeyCode == Enum.KeyCode.Return then
		if not ConsoleGui.Enabled then return end
		ConsoleModule.Enter()
	else
		if ConsoleGui.Enabled and not TextBox:IsFocused() then
			TextBox:CaptureFocus()
		end
	end

end)

-- Typing Attribute
TextBox.Focused:Connect(function()
	player:SetAttribute("Typing", true)
end)

TextBox.FocusLost:Connect(function()
	player:SetAttribute("Typing", false)
end)

--[[
	If GUI is Enabled on Start, make sure connections are enabled.
]]
if ConsoleGui.Enabled then
	ConnectCommandConnections()
end
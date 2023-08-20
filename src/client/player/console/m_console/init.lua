local Console = {
	LineMaxChar = 66,
	MaxLines = 33,
}

local Commands = require(script:WaitForChild("Commands"))

Console.KeyWords = {
	player = Color3.new(0.333333, 1, 1)
}

Console.CurrentLinesIndex = 0
Console.CurrentLinesTable = {}
Console.IsShifting = false

local gui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("Console")
local returnTextFrame = gui:WaitForChild("ReturnTextFrame")
local returnTextBoxLine = returnTextFrame.TextBoxLineDefault
local enterTextFrame = gui:WaitForChild("EnterTextFrame")

local function robloxQuickError(msg)
	task.spawn(function()
		error(msg)
	end)
end

function Console.ShiftLinePositions()
	if Console.IsShifting then
		local timeout = tick() + 10
		repeat task.wait() until not Console.IsShifting or tick() >= timeout
	end
	
	Console.IsShifting = true
	
	local toDestroy
	for i, v in pairs(Console.CurrentLinesTable) do
		local numberLabel = v:WaitForChild("NumberLabel", 3)
		if i == 1 then
			toDestroy = v
		end
		if v.Name == "TextBoxLine" then
			local n = i-2
			v.Position = UDim2.fromScale(v.Position.X.Scale, n * 0.03)
			if not numberLabel then continue end
			numberLabel.Text = tostring(n + 1)
		end
	end
	
	toDestroy:Destroy()
	table.remove(Console.CurrentLinesTable, 1)
	
	Console.IsShifting = false
end

function Console.Return(str, warning, err)
	if not str then return end
	if Console.IsShifting then
		local timeout = tick() + 10
		repeat task.wait() until not Console.IsShifting or tick() >= timeout
	end
	local max = Console.LineMaxChar
	local split = {}
	if string.len(str) > max then
		local first = 1
		local last = max
		local div = string.len(str)/max
		for i = 1, math.ceil(div) do
			if i ~= 1 then
				first = last + 1
				if string.len(str) - max * i < max then
					last = string.len(str)
				else
					last += max
				end
			end
			table.insert(split, string.sub(str, first, last))
		end
	else
		split = {str}
	end
	
	for i, v in pairs(split) do
		Console.CurrentLinesIndex += 1
		
		if Console.CurrentLinesIndex == 1 then
			returnTextBoxLine.Visible = false
		end
		
		if Console.CurrentLinesIndex > Console.MaxLines then
			Console.CurrentLinesIndex = Console.MaxLines
			Console.ShiftLinePositions()
		end
		
		local newLine = returnTextBoxLine:Clone()
		newLine.Name = "TextBoxLine"
		task.spawn(function()
			newLine:WaitForChild("NumberLabel").Text = tostring(Console.CurrentLinesIndex)
			newLine.Text = v
			newLine.Position = UDim2.fromScale(newLine.Position.X.Scale, (Console.CurrentLinesIndex - 1) * 0.03)
			newLine.Parent = returnTextFrame
			newLine.Visible = true
		end)
		
		newLine.TextColor3 = (warning and Color3.new(0.709804, 0.560784, 0.0156863)) or (err and Color3.new(0.619608, 0, 0)) or returnTextBoxLine.TextColor3
		
		table.insert(Console.CurrentLinesTable, newLine)
	end
	
end

function Console.Enter()
	local stringToEnter = enterTextFrame.TextBox.Text
	--local split = string.split(stringToEnter, " ")
	--local command = split[1]
	
	print(stringToEnter)
	local split = {}
	for word in string.gmatch(stringToEnter, "%S+") do
		print(word)
		table.insert(split, word)
	end
	
	local command = split[1]
	
	enterTextFrame.TextBox.Text = ""
	
	if not command then
		robloxQuickError("Could not register command.")
		return
	end
	
	local commandTable = false
	for i, v in pairs(Commands) do
		if string.lower(i) == string.lower(split[1]) and v.Public and v.Function then
			commandTable = v
			break
		end
	end
	
	if not commandTable then
		robloxQuickError("Could not find command " .. tostring(command))
		return
	end
	
	-- remove action to send arguments
	split[1] = nil
	
	commandTable.Function(table.unpack(split))
end

function Console.Clear()
	for i, v in pairs(returnTextFrame:GetChildren()) do
		if v.Name == "TextBoxLineDefault" then
			v.Visible = true
		elseif v.Name == "TextBoxLine" then
			v:Destroy()
		end
	end
	Console.CurrentLinesTable = {}
	Console.CurrentLinesIndex = 0
end

return Console
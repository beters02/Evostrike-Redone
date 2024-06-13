local Types = require(script.Parent:WaitForChild("Types"))
local Commands = require(script.Parent:WaitForChild("Commands"))
--[[local Framework = require(ReplicatedStorage:WaitForChild("ConsoleFramework"))
local Connections = Framework.Connections]]

local AutoFill: Types.AutoFillModule = {}

local isInit = false
local lastStrLen = 0
local currStr = ""
local currStrLen = 0
local cursorPos = 0
local cursorSelectedIndex = 0
local colorSelected = Color3.new()
local colorDefault = Color3.new()

local commands_arr: {string} = {}
local recent_slices_dict: {[string]: {string}} = {}
local curr_possible_commands_from_input_dict: {[string]: {label: TextLabel, itemsArrIndex: number}} = {}
local items_arr = {}

local function createItemLabel(console: Types.CConsole, command: string)
    local item = console.autofr.Item:Clone()
    item.Parent = console.autofr
    item.Text = command
    item.Visible = true
    return item
end

local function addCommandItem(console: Types.CConsole, command: string, slice: string?)
    local label = createItemLabel(console, command)
    table.insert(items_arr, label)

    curr_possible_commands_from_input_dict[command] = {
        label = label,
        itemsArrIndex = #items_arr
    }

    if slice then
        table.insert(recent_slices_dict[slice], command)
    end
end

local function fixItemsIndex()
    for i, v in pairs(items_arr) do
        local obj = curr_possible_commands_from_input_dict[v.Text]
        if obj then
            obj.itemsArrIndex = i
        else
            items_arr[i] = nil
        end
    end
end

local function destroyNonSliceCommands(slice: string)
    local updated = false

    for command, _ in pairs(curr_possible_commands_from_input_dict) do
        if not string.match(command, slice) then
            updated = true
            local obj = curr_possible_commands_from_input_dict[command]
            table.remove(items_arr, obj.itemsArrIndex)
            obj.label:Destroy()
            curr_possible_commands_from_input_dict[command] = nil
        end
    end

    if updated then
        fixItemsIndex()
    end
end

local function setCommandsToRecentSlice(console: Types.CConsole, slice: string)
    for _, command in pairs(recent_slices_dict[slice]) do
        if not curr_possible_commands_from_input_dict[command] then
            addCommandItem(console, command)
        end
    end
    destroyNonSliceCommands(slice)
end

-- Get all possible commands from first letter (creates items)
local function getCommandsFromChar(console: Types.CConsole, char: string)
    if recent_slices_dict[char] then
        setCommandsToRecentSlice(console, char)
        return
    end

    recent_slices_dict[char] = {}
    for _, command in pairs(commands_arr) do
        if string.sub(command, 1, 1) == char then
            addCommandItem(console, command, char)
        end
    end
end

-- Remove possible commands (destroys items)
local function checkCommandsFromSlice(console: Types.CConsole, slice: string)
    if recent_slices_dict[slice] then
        setCommandsToRecentSlice(console, slice)
        return
    end

    destroyNonSliceCommands(slice)

    recent_slices_dict[slice] = {}
    for command, _ in pairs(curr_possible_commands_from_input_dict) do
        table.insert(recent_slices_dict[slice], command)
    end
end

local function updateCursor()
    if cursorSelectedIndex ~= 0 then
        items_arr[cursorSelectedIndex].BackgroundColor3 = colorDefault
    end

    if cursorPos ~= 0 then
        items_arr[cursorPos].BackgroundColor3 = colorSelected
    end

    cursorSelectedIndex = cursorPos
end

function AutoFill.init(console: Types.CConsole)
    colorDefault = console.cfg.auto_fill_item_color_default
    colorSelected = console.cfg.auto_fill_item_color_selected
    if not isInit then
        isInit = true
        for cmd, _ in pairs(Commands) do
            table.insert(commands_arr, cmd)
        end
    end
end

function AutoFill.updateResults(console: Types.CConsole)
    
    currStr = console:GetText()
    currStrLen = string.len(currStr)
    
    if currStrLen == 0 then
        AutoFill.finish()
        return
    end

    AutoFill.resetCursor()

    if lastStrLen == 0 or currStrLen == 1 then
        getCommandsFromChar(console, currStr)
    elseif currStrLen > lastStrLen or currStrLen < lastStrLen then
        checkCommandsFromSlice(console, currStr)
    end

    lastStrLen = currStrLen
end

function AutoFill.cursorUp()
    cursorPos -= 1
    if cursorPos <= 0 then
        cursorPos = #items_arr
    end
    updateCursor()
end

function AutoFill.cursorDown()
    cursorPos += 1
    if cursorPos >= #items_arr then
        cursorPos = 0
    end
    updateCursor()
end

function AutoFill.resetCursor()
    cursorPos = 0
    updateCursor()
end

-- when a player hits enter, check if they have autofill option selected
-- returns selected command or false
function AutoFill.checkSelected()
    if cursorSelectedIndex ~= 0 then
        return items_arr[cursorSelectedIndex].Text
    end
    return false
end

function AutoFill.tab()
    if #items_arr > 0 then
        cursorSelectedIndex = #items_arr
        return AutoFill.checkSelected()
    end
    return false
end

function AutoFill.finish()
    lastStrLen = 0
    currStr = ""
    currStrLen = 0
    cursorPos = 0
    cursorSelectedIndex = 0

    for _, v in pairs(curr_possible_commands_from_input_dict) do
        if v then
            v.label:Destroy()
        end
    end
    curr_possible_commands_from_input_dict = {}
    recent_slices_dict = {}
    items_arr = {}
end

return AutoFill
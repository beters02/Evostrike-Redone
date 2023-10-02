local UserInputService = game:GetService("UserInputService")
local Framework = require(game.ReplicatedStorage.Framework)
local Ability = require(Framework.Service.AbilityService.Ability).new(script.Parent:WaitForChild("ModuleObject").Value)
local PlayerData = require(Framework.Module.shared.PlayerData.m_clientPlayerData)
local Strings = require(Framework.Module.lib.fc_strings)
local UIState = require(Framework.Module.m_states).State("UI")

local Path = "options.keybinds." .. Ability.Options.inventorySlot .. "Ability"
local Key = PlayerData:Get(Path)
Ability.Key = Key
Ability.Frame.Key.Text = Strings.convertFullNumberStringToNumberString(Key)
PlayerData:Changed(Path, function(newValue)
    Key = newValue
    Ability.Frame.Key.Text = Strings.convertFullNumberStringToNumberString(Key)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if UIState:hasOpenUI() or Ability.Player:GetAttribute("Typing") or gp then return end
    if input.KeyCode == Enum.KeyCode[Key] then
        Ability:UseCore()
    end
end)
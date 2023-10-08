local player = game:GetService("Players").LocalPlayer
if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
--game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
game:GetService("UserInputService").MouseIconEnabled = false
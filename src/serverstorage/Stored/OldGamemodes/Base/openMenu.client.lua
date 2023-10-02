-- force the player's main menu to open and connect the load starter island button

local mainMenu = game:GetService("Players").LocalPlayer.PlayerScripts:WaitForChild("MainMenu")
mainMenu = require(mainMenu)
if not mainMenu.isInit then repeat task.wait() until mainMenu.isInit end
mainMenu.open()
mainMenu.page._stored.Home:_enableLoadStarterIslandButton()
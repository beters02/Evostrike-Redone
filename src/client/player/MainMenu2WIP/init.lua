--[[
    Init MainMenu Module when player joins the game
    Get MainMenuType and Distribute to all pages on initialization
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GamemodeService = require(Framework.Service.GamemodeService2)

-- Button Sound Names (Stored in Gui.Sounds)
local Enum_ButtonSoundNames = {
    PurchaseSound1 = "purchaseSound1"
}

-- Main Menu Module
local MainMenu = {
    Connections = {},
    BaseConnections = {}, -- Dont disconnect these
    Pages = {},
    ButtonSounds = {},
    CurrentOpenPage = false,
    Gui = false,
    CurrentMenuType = false
}

function getPage(pageName)
    return MainMenu.Pages[pageName]
end

function getPages()
    return MainMenu.Pages
end

function menuTypeChanged(newMenuType)
    local self = MainMenu
    if self.CurrentMenuType == newMenuType then
        return
    end
    for _, page in pairs(getPages()) do
        page:MenuTypeChanged(newMenuType)
    end
end

function MainMenu:Initialize(gui)
    -- init pages
    self.Gui = gui

    -- init button sounds
    local bsounds = gui:WaitForChild("Sounds")
    for i, v in pairs(Enum_ButtonSoundNames) do
        self.ButtonSounds[i] = bsounds:FindFirstChild(v)
    end

    -- init GamemodeService2 MenuType
    self.CurrentMenuType = GamemodeService:GetMenuType()
    self.BaseConnections.MenuTypeChanged = GamemodeService:MenuTypeChanged(menuTypeChanged)
end

function MainMenu:Open()
    self.Gui.Enabled = true
    if self.CurrentOpenPage then
        self.CurrentOpenPage:Open()
    end
end

function MainMenu:Close()
    self:ClosePage()
    self.Gui.Enabled = false
end

-- Automatically Closes Current Page and Opens New One
function MainMenu:OpenPage(pageName)
    local newPage = getPage(pageName)
    self:ClosePage()
    newPage:Open()
    self.CurrentOpenPage = newPage
end

-- Closes the Currently Opened Page
function MainMenu:ClosePage()
    if self.CurrentOpenPage then
        self.CurrentOpenPage:Close()
    end
end

function MainMenu:PlayButtonSound(buttonType)
    self.ButtonSounds[buttonType]:Play()
end

return MainMenu
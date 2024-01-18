--[[
    Init MainMenu Module when player joins the game
    Get MainMenuType and Distribute to all pages on initialization
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local GamemodeService = require(Framework.Service.GamemodeService2)
local States = require(Framework.Module.States)
local UIState = States:Get("UI")
-- work

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

-- Initialize Pages, Sounds and GamemodeService
function MainMenu:Initialize(gui)
    self.Gui = gui
    self.CurrentMenuType = GamemodeService:GetMenuType()
    self.BaseConnections.MenuTypeChanged = GamemodeService:MenuTypeChanged(menuTypeChanged)
    initPages(self)
    initButtonSounds(self)
    self.CurrentOpenPage = getPage("Home")
end

-- Open the Menu, Re-opens last open page
function MainMenu:Open()
    self.Gui.Enabled = true
    if self.CurrentOpenPage then
        self.CurrentOpenPage:Open()
    end
    UIState:removeOpenUI("MainMenu")
	UIState:addOpenUI("MainMenu", self.Gui, true)
end

-- Close the Menu, Closes current page and sets to last open
function MainMenu:Close()
    self:ClosePage()
    self.Gui.Enabled = false
    UIState:removeOpenUI("MainMenu")
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

-- Play a Button Sound
function MainMenu:PlayButtonSound(buttonType)
    self.ButtonSounds[buttonType]:Play()
end

-- Get the CurrentMenuType
function MainMenu.MenuType()
    return MainMenu.CurrentMenuType
end

--
--
--

function getPage(pageName) return MainMenu.Pages[pageName] end
function getPages() return MainMenu.Pages end

function initButtonSounds(self)
    local bsounds = self.Gui:WaitForChild("Sounds")
    for i, v in pairs(Enum_ButtonSoundNames) do
        self.ButtonSounds[i] = bsounds:FindFirstChild(v)
    end
end

function menuTypeChanged(newMenuType)
    local self = MainMenu
    if self.CurrentMenuType == newMenuType then return end
    self.CurrentMenuType = newMenuType
    for _, page in pairs(getPages()) do
        page:MenuTypeChanged(newMenuType)
    end
end

function initPages(self)
    -- Frames which names end in "Frame: are initialized as pages and moved to Pages Folder
    local pagesFolder = Instance.new("Folder", self.Gui)
    pagesFolder.Name = "Pages"
    for _, frame in pairs(self.Gui:GetChildren()) do
        if not string.match(frame.Name, "Frame") then continue end
        frame.Parent = pagesFolder
        local pageName = string.gsub(frame.Name, "Frame", "")

        -- if we can't find a module for the page, it gets the Base class.
        local module = script.Page:FindFirstChild(pageName) or script.Page
        self.Pages[pageName] = require(module).new(self, frame)
    end
end

return MainMenu
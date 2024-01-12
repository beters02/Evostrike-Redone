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

function MainMenu:Initialize(gui)
    self.Gui = gui
    initPages(self)
    initButtonSounds(self)
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

function MainMenu.MenuType()
    return MainMenu.CurrentMenuType
end

return MainMenu
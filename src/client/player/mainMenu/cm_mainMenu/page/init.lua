--[[
    This is a MODULE which creates CLASSES
]]

local page = {}
page.__index = page

local EnableBindable = script.Parent.Parent.EnableMenuBindable

--[[ Page Module Private Access Functions ]]

function page.init(self) -- self = main

    -- create page table for main table in cm_mainMenu
    local _page = {}
    _page = {}
    _page._opened = {} -- currently opened pages
    for i, v in pairs(page) do
        if i == "init" or i == "new" then continue end
        _page[i] = v
    end
    
    -- initialize page location here since it is a client script
    _page._loc = self.player.PlayerScripts.mainMenu.cm_mainMenu.page

    -- init base page class
    _page._baseClass = require(_page._loc:WaitForChild("Base"))

    -- this is where we will store the locations
    -- of all the pages for easy access
    _page._stored = {}

    for i, v in pairs(self.gui:GetChildren()) do

        -- pages must be frames, and their names must end with "Frame"
        if not v:IsA("Frame") or not string.match(v.Name, "Frame") then continue end

        -- remove "Frame" from string,
        -- create class with new name
        _page._stored[string.gsub(v.Name, "Frame", "")] = _page._baseClass.new(self, _page, string.gsub(v.Name, "Frame", ""))

    end

    return setmetatable(_page, page)
end

--[[
    Page Module Public Access Functions
]]

-- Dont include "Frame" in pageName
function page:OpenPage(pageName: string, dontCloseOtherPages: boolean)
    local class = self:FindPage(pageName)
    if class then
        if not dontCloseOtherPages then self:CloseAllPages() end
        class:Open()
        self._opened[pageName] = class
    end
end

function page:ClosePage(pageName: string)
    local class = self:FindPage(pageName)
    if class then
        class:Close()
    end
    self._opened[pageName] = nil
end

function page:CloseAllPages()
    for i, v in pairs(self._opened) do
        v:Close()
    end
    self._opened = {}
end

function page:FindPage(pageName: string) -- Do not add "Frame" when calling pageName
    local sucess, foundClass = pcall(function()
        return self._stored[pageName]
    end)
    return foundClass
end

function page:GetOpenPages()
    return self._opened
end

return page
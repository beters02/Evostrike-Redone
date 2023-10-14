--[[ Main Menu Module ]]
--[[ Initialized in MainMenuGui.Main when added from Server ]]

export type Page = {
    Name: string,
    Frame: Frame,

    Open: () -> (),
    Close: () -> (),
}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
if RunService:IsServer() then
    return require(script:WaitForChild("Server"))
end

local MainMenu = {Opened = false, Pages = {}, CurrentOpenPage = false, Connections = {}}
local Page = {}
local Pages = script:WaitForChild("Pages"):GetChildren()

--@class Page Class
function Page.new(pageFrame: Frame)
    local module = Pages:FindFirstChild(pageFrame) and Pages[pageFrame]
    assert(module, "Page must have Page Module! " .. tostring(pageFrame.Name))
    local self = setmetatable(require(module), Page)
    self.Menu = MainMenu
    self.Name = string.gsub(pageFrame.Name, "Frame", "")
    self.Frame = pageFrame
    if self.init then
        self:init()
    end
    return self :: Page
end

function Page:Open()
    self.Location.Visible = true
    self:_OpenPost()
end

function Page:_OpenPost()
end

function Page:Close()
    self.Location.Visible = false
    self:_ClosePost()
end

function Page:_ClosePost()
end
--

--@module Main Menu
function MainMenu.init(gui)
    MainMenu.gui = gui
    for _, frame in pairs(gui:GetChildren()) do
        if string.match(frame.Name, "Frame") and frame:IsA("Frame") and not frame:GetAttribute("NotMain") then
            local page = Page.new(frame)
            MainMenu.Pages[page.Name] = page
        end
    end
    MainMenu:Connect()
    MainMenu:OpenPage("Home")
end

function MainMenu:Connect()
    for _, frame in pairs(self.gui:WaitForChild("TopBar"):GetChildren()) do
        local page = string.gsub(frame.Name, "ButtonFrame", "")
        page = MainMenu.Pages[page]
        self.Connections[page.Name.."_Open"] = frame:WaitForChild("TextButton").MouseButton1Click:Connect(function()
            MainMenu:OpenPage(page)
        end)
    end
    self.Connections.Input = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.M then
            if self.Opened then
                self:Close()
            else
                self:Open()
            end
        end
    end)
end

function MainMenu:Disconnect()
    for _, conn in pairs(self.Connections) do
        conn:Disconnect()
    end
    table.clear(self.Connections)
end

--

function MainMenu:Open()
    self.Opened = true
    self:Connect()
end

function MainMenu:Close()
    self.Opened = false
end

function MainMenu:OpenPage(page)
    MainMenu:CloseCurrentPage()
    page:Open()
    self.CurrentOpenPage = page
end

function MainMenu:ClosePage(page)
    page:Close()
end

function MainMenu:CloseCurrentPage()
    if self.CurrentOpenPage then
        self.CurrentOpenPage:Close()
        self.CurrentOpenPage = false
    end
end

function MainMenu:CloseAllPages()
    for _, page in pairs(self.Pages) do
        page:Close()
    end
    self.CurrentOpenPage = false
end

--@MenuTypes
MainMenu.MenuTypes = {}
MainMenu.MenuTypes.Game = function()
    
end

MainMenu.MenuTypes.Lobby = function()
    if MainMenu.Connections.Input then
        MainMenu.Connections.Input:Disconnect()
        MainMenu.Connections.Input = nil
    end
    MainMenu:Open()
end

function MainMenu:SetMenuType(MenuType: "Game" | "Lobby")
    MainMenu.MenuTypes[MenuType]()
end

return MainMenu
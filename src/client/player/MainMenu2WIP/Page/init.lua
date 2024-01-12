-- Page Base Class

-- Some Page Functions can be overridden, call self._[Function] for base function.
-- init, Open, Close, Connect, Disconnect can all be overridden.
-- EX:
--[[

    local HomePage = {}

    function HomePage.new()
        return setmetatable(Page.new(m, f), HomePage)
    end

    -- Custom Open Function while still calling it's base function
    function HomePage:Open()
        self._Open()
        -- do custom functionality here
    end
]]

local Page = {}
Page.__index = Page

-- Create a Page Object
function Page.new(mainMenu, frame)
    local self = setmetatable({}, Page)
    self.Frame = frame
    self.Main = mainMenu
    self.Connections = {}

    self._init = function()
        self:MenuTypeChanged(self.Main.MenuType())
    end

    self._Open = function()
        self.Frame.Visible = true
        self:Connect()
    end

    self._Close = function()
        self.Frame.Visible = false
        self:Disconnect()
    end

    -- Just so you don't get errors when using self._Connect
    self._Connect = function() end

    self._Disconnect = function()
        for _, v in pairs(self.Connections) do
            v:Disconnect()
        end
    end
    return self
end

-- Page Initilization, Called in MainMenuModule when Pages are Initialized
function Page:init()
    self._init()
end

-- Open the Page
function Page:Open()
    self._Open()
end

-- Close the Page
function Page:Close()
    self._Close()
end

-- Called in Page:Open(), Base function does nothing.
function Page:Connect()
    self._Connect()
end

-- Called in Page:Close(), Disconnects all connections in self.Connections
function Page:Disconnect()
    self._Disconnect()
end

-- Change parts of the Page when the MenuType is Changed!
function Page:MenuTypeChanged(newMenuType)
end

-- Correctly add a Connection to a page,
-- Prevents Connections being added to dictionary and overriding the current one, causing a memory leak.
function Page:AddConnection(name, connection)
    if self.Connections[name] then
        self.Connections[name]:Disconnect()
    end
    self.Connections[name] = connection
end

return Page
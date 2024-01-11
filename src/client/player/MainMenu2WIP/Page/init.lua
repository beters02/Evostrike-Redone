-- Page Base Class

-- All Page Functions can be Overridden, call self._[Function] for base function.
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

function Page.new(mainMenu, frame)
    local self = setmetatable({}, Page)
    self.Frame = frame
    self.Main = mainMenu
    self.Connections = {}
    self._Open = function()
        self.Frame.Visible = true
        self:Connect()
    end
    self._Close = function()
        self.Frame.Visible = false
        self:Disconnect()
    end
    self._Disconnect = function()
        for _, v in pairs(self.Connections) do
            v:Disconnect()
        end
    end
    self:init()
    return self
end

-- Page Initilization, Called in Page.new()
function Page:init()
end

function Page:Open()
    self._Open()
end

function Page:Close()
    self._Close()
end

-- Called in Page:Open()
function Page:Connect()
end

-- Called in Page:Close()
function Page:Disconnect()
    self._Disconnect()
end

-- Change the Page when the MenuType is Changed!
function Page:MenuTypeChanged(newMenuType)
end

return Page
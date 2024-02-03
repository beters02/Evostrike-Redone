local Page = {}
Page.__index = Page

-- Init a Frame as a Page
function Page.new(frame)
    local self = setmetatable({}, Page)
    self.Frame = frame
    return self
end

-- Override Open Func
function Page:Open()
    self:_open()
end

-- Override Close Func
function Page:Close()
    self:_close()
end

function Page:_open()
    self.Visible = true
    self:_connect()
end

function Page:_close()
    self.Visible = false
    self:_disconnect()
end

function Page:_connect()
    
end

function Page:_disconnect()
    
end

return Page
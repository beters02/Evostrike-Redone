local pageClass = {}
pageClass.__index = pageClass

function pageClass.new(main, basePageTable, pageName)
    local self = basePageTable._loc:FindFirstChild(pageName) and require(basePageTable._loc[pageName]) or {} -- check if page has it's own class
    self.Name = pageName
    self.Location = main.gui[pageName.."Frame"]
    self._mainPageModule = basePageTable
    self._sendMessageGui = require(basePageTable._loc.Parent.sendMessageGui)

    if self.init then self = self:init(main) end
    return setmetatable(self, pageClass)
end

function pageClass:Open()
    self.Location.Visible = true
end

function pageClass:Close()
    self.Location.Visible = false
end

return pageClass
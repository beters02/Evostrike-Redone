local base = {}
base.__index = base
base._baseLocation = game:GetService("ReplicatedStorage"):WaitForChild("Services"):WaitForChild("QueueService").Class.base

--[[ Configuration ]]
base.Name = "Base"
base.QueueInterval = 5
base.MaxParty = 8
base.MinParty = 2

--[[ Class ]]

function base.new(class: string)

    -- search for class
    local _c = base._baseLocation.Parent:FindFirstChild(class)
    if not _c then return false, "Couldn't find class " .. tostring(class) end
    _c = require(_c)

    -- meta class iheritence
    _c = setmetatable(_c, base)

    -- initialize store module
    _c.storeModule = require(base._baseLocation.store)

    local success, err = pcall(function()
        _c.storeModule:Init() -- grab queue datastore
    end)

    if not success then
        error(err)
        return false
    end

    return _c
end

return base
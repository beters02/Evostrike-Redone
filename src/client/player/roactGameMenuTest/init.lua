local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Roact = require(Framework.shm_Roact.Location)

local test = {}

function test.init()
    
    test.menu = Roact.createElement("ScreenGui", {}, {
        
    })

end

return test
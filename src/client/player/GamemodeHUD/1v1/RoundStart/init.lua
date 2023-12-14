local RoundStart = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rbxui = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("rbxui")

--@summary Clears previous round uis.
function RoundStart.init()
    require(rbxui).Tag.DestroyAllIn("DestroyOnRoundStart")
end

return RoundStart
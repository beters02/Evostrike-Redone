local UserInputService = game:GetService("UserInputService")

local Inputs = {}

--@summary Check if both keys are down given an InputObject.
function Inputs.BothKeysDownInput(input, k1, k2)
    if (input.KeyCode == Enum.KeyCode[k1] and UserInputService:IsKeyDown(Enum.KeyCode[k2]))
    or (input.KeyCode == Enum.KeyCode[k2] and UserInputService:IsKeyDown(Enum.KeyCode[k1])) then
        return true
    end
    return false
end

--@summary Check if both keys are down.
function Inputs.BothKeysDown(k1, k2)
    return UserInputService:IsKeyDown(Enum.KeyCode[k1]) and UserInputService:IsKeyDown(Enum.KeyCode[k2])
end

return Inputs
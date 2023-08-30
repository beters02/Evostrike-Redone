local Debris = game:GetService("Debris")
local player = game:GetService("Players").LocalPlayer
local hrp = (player.Character or player.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
hrp.Anchored = true

local debounce = false
local _endt = tick() + 0.5
local conn

local function finished()
    debounce = true
    hrp.Anchored = false
    Debris:AddItem(script, 3)
    conn:Disconnect()
end

conn = game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp or debounce or input.UserInputType == Enum.UserInputType.Focus or string.match(input.UserInputType.Name, "Mouse") then return end
    finished()
end)

--repeat task.wait() until debounce or tick() >= _endt
repeat task.wait() until debounce or tick() >= _endt

if not debounce then
    if not player:GetAttribute("Loaded") then repeat task.wait() until player:GetAttribute("Loaded") end
    finished()
end
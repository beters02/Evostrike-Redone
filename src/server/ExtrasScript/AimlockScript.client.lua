local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local cam = workspace.CurrentCamera
local hrp = char:WaitForChild("HumanoidRootPart")

local locked = false
local CLOSET_AMOUNT = 10

local function GetCharacters()
    local chars = {}
    for _, v in pairs(workspace:GetChildren()) do
        if v:FindFirstChild("Humanoid") then
            table.insert(chars, v)
        end
    end
    return chars
end

local function GetNearestCharacter()
    local chars = GetCharacters()
    if #chars <= 1 then
        return false, "Can't lock. Not enough players"
    end

    local nearestChar = false
    local nearestDist = 0
    for _, v in pairs(chars) do
        local dist = (v.HumanoidRootPart.CFrame.Position - hrp.CFrame.Position).Magnitude
        if not nearestChar or nearestDist < dist then
            nearestChar = v
            nearestDist = dist
        end
    end

    return nearestChar
end

local function InputBegan(input)
    if input.KeyCode == Enum.KeyCode.X then
        locked = true
    end
end

local function InputEnded(input)
    if input.KeyCode == Enum.KeyCode.X then
        locked = false
    end
end

local function Update(dt)
    if not locked then
        return
    end

    local nearestChar, err = GetNearestCharacter()
    if not nearestChar then
        print(err)
        return
    end

    local camCF = CFrame.new(cam.CFrame.Position, nearestChar.Head.CFrame.Position)
    if CLOSET_AMOUNT == 0 then
        cam.CFrame = camCF
    else
        TweenService:Create(cam, TweenInfo.new(CLOSET_AMOUNT*dt), {CFrame = camCF}):Play()
    end
end

UserInputService.InputBegan:Connect(InputBegan)
UserInputService.InputEnded:Connect(InputEnded)
RunService.RenderStepped:Connect(Update)
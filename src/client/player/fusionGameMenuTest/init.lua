local Players = game:GetService("Players")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local UserInputService = game:GetService("UserInputService")
local Fusion = require(Framework.shm_Fusion.Location)

local New = Fusion.New
local Children = Fusion.Children
--[[local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local State = Fusion.State]]

local Value = Fusion.Value

local test = {}
test.__index = test

--

function test:Open()
    self.menuGui.Enabled = true
end

function test:Close()
    self.menuGui.Enabled = false
end

--

function test.init()

    test._player = Players.LocalPlayer
    test._mainConn = {}

    test.menuGui = New "ScreenGui" {
        Parent = Players.LocalPlayer.PlayerGui,

        Name = "FusionMenu",
        ResetOnSpawn = false,
        ZIndexBehavior = "Sibling",
        IgnoreGuiInset = true,
        Enabled = false,

        [Children] = {
            New "Frame" {
                Name = "TopBar",
                Size = UDim2.fromScale(1, 0.1),
                Position = UDim2.fromScale(0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5)
            }
        }
    }

    -- init options states?
    test:initStates()

    -- finalize
    local _attconn
    if not test._player:GetAttribute("Loaded") then
        _attconn = test._player:GetAttributeChangedSignal("Loaded"):Connect(function()
            if test._player:GetAttribute("Loaded") then
                test:Open()
                _attconn:Disconnect()
            end
        end)
    end

    return test
end

function test:initStates()
    self.states = {_conn = {}}

    -- init options states
    self.states.options = {
        test = Value(1)
    }

end

function test:initInputConnections()
    self._mainConn.inputBegan = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end

        if input.KeyCode == Enum.KeyCode.M then
            
        end
    end)
end

--

return test.init()
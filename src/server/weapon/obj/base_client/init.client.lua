local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Types = Framework._types

local co: Types.Class = Framework.__index(Framework, "shc_cameraObject")
co.New("ak47")
local Framework = game:GetService("ReplicatedStorage"):WaitForChild("Framework", 3)
if not Framework then return end

-- Create a new toolbar section titled "Custom Script Tools"
local toolbar = plugin:CreateToolbar("CSL ^3 Framework")

-- Add toolbar buttons
local mmeditButton = toolbar:CreateButton("Map Mode: Edit", "Group all workspace objects except Map and ungroup Map Model.", "rbxassetid://4458901886")
local mmplayButton = toolbar:CreateButton("Map Mode: Play", "Regroup Map and ungroup workspace objects model.", "rbxassetid://4458901886")
local vhpackbutton = toolbar:CreateButton("Version Handle: Pack", "Creates a model to distribute in ServerStorage and deletes items after they are cloned", "rbxassetid://4458901886")
local vhunpackbutton = toolbar:CreateButton("Version Handle: Unpack", "Unpacks a game model, replaces current models", "rbxassetid://4458901886")
local vhpushupdatebutton = toolbar:CreateButton("Version Handle: Push Update", "Update game to new version, creates a model to distribute in ServerStorage", "rbxassetid://2790459043")
local vhpullupdatebutton = toolbar:CreateButton("Version Handle: Pull Update", "Update game to new version, creates a model to distribute in ServerStorage", "rbxassetid://2790459347")
--

-- Make button clickable even if 3D viewport is hidden
mmeditButton.ClickableWhenViewportHidden = true
mmplayButton.ClickableWhenViewportHidden = true
vhpackbutton.ClickableWhenViewportHidden = true
vhunpackbutton.ClickableWhenViewportHidden = true
--

-- [[ Map Mode ]]
local map = require(script:WaitForChild("map"))
--

-- [[ Version Handling ]]
local vh = require(script:WaitForChild("versionHandle"))

local vhSelf = {}
vhSelf.vh_isupdating = false
vhSelf.vh_isunpacking = false
vhSelf.vhUpdateConfirmGui = script:WaitForChild("vhUpdateConfirmGui", 10):Clone()
vhSelf.vhPackWithMapConfirmGui = script:WaitForChild("vhPackWithMapConfirmGui", 10):Clone()
vhSelf.vhPullConfirmGui = script:WaitForChild("ConfirmPull", 10):Clone()

--

local self

local function init()
	map.init(mmeditButton, mmplayButton)

	vhSelf.getMapMode = map.GetMode
	vhSelf.mm_play = function() return map.Mode("Play") end
	vhSelf.mm_ungroupChildren = map.Ungroup

	vh.init(vhSelf, vhpushupdatebutton, vhpullupdatebutton, vhunpackbutton, vhpackbutton)
end

init()
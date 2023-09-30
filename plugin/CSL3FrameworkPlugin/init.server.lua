local Debris = game:GetService("Debris")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local sp = game:GetService("StarterPlayer")

-- Create a new toolbar section titled "Custom Script Tools"
local toolbar = plugin:CreateToolbar("CSL ^3 Framework")

-- Add toolbar buttons
local mmeditButton = toolbar:CreateButton("Map Mode: Edit", "Group all workspace objects except Map and ungroup Map Model.", "rbxassetid://4458901886")
local mmplayButton = toolbar:CreateButton("Map Mode: Play", "Regroup Map and ungroup workspace objects model.", "rbxassetid://4458901886")
local vhpackbutton = toolbar:CreateButton("Version Handle: Pack", "Creates a model to distribute in ServerStorage and deletes items after they are cloned", "rbxassetid://4458901886")
local vhunpackbutton = toolbar:CreateButton("Version Handle: Unpack", "Unpacks a game model, replaces current models", "rbxassetid://4458901886")
local vhpushupdatebutton = toolbar:CreateButton("Version Handle: Push Update", "Update game to new version, creates a model to distribute in ServerStorage", "rbxassetid://2790459043")
local vhpullupdatebutton = toolbar:CreateButton("Version Handle: Pull Update", "Update game to new version, creates a model to distribute in ServerStorage", "rbxassetid://2790459347")


-- Make button clickable even if 3D viewport is hidden
mmeditButton.ClickableWhenViewportHidden = true
mmplayButton.ClickableWhenViewportHidden = true
vhpackbutton.ClickableWhenViewportHidden = true
vhunpackbutton.ClickableWhenViewportHidden = true

--

local self = {}
self.vh_isupdating = false
self.vh_isunpacking = false
self.vhUpdateConfirmGui = script:WaitForChild("vhUpdateConfirmGui", 10):Clone()
self.vhPackWithMapConfirmGui = script:WaitForChild("vhPackWithMapConfirmGui", 10):Clone()

-- [[ Map Mode ]]
self.currentMapMode = workspace:FindFirstChild("Map") and "play" or "edit"
self.canChangeMapMode = true

function self.mm_groupChildren(parent, rIgnoreList)
	
	local ignoreList = {}
	
	if rIgnoreList then
		for i, v in rIgnoreList do
			ignoreList[v] = v
		end
	end
	
	local model = Instance.new("Model")
	model.Parent = workspace
	for i, v in pairs(parent:GetChildren()) do
		if v == model then continue end
		if ignoreList[v.Name] then continue end
		if v:IsA("Terrain") or v:IsA("Camera") then continue end
		
		v.Parent = model
	end
	return model
end

function self.mm_ungroupChildren(model, whereTo)
	for i, v in pairs(model:GetChildren()) do
		v.Parent = whereTo
	end
	model:Destroy()
end

function self.mm_edit()
	
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	
	self.canChangeMapMode = false
	currentMapMode = "edit"
	
	-- change opposite button gui pressed state
	--mmplayButton:SetActive(false)
	
	-- group all objects EXCEPT
	local except = {"Map", "CollisionBox", "Spawns", "MovementIgnore"}
	local workspaceobjects = self.mm_groupChildren(workspace, except)
	workspaceobjects.Name = "WorkspaceObjects"
	
	-- move barriers
	workspaceobjects:WaitForChild("Barriers").Parent = game:GetService("ServerStorage")
	
	-- ungroup map
	self.mm_ungroupChildren(map, workspace)
	
	self.canChangeMapMode = true
	ChangeHistoryService:SetWaypoint("Map Mode changed to Edit.")
end

function self.mm_play()
	
	local workspaceobjects = workspace:FindFirstChild("WorkspaceObjects")
	if not workspaceobjects then return end
	
	self.canChangeMapMode = false
	currentMapMode = "play"
	
	-- change opposite button gui pressed state
	--mmeditButton:SetActive(false)

	-- group all objects EXCEPT
	local except = {"WorkspaceObjects", "CollisionBox", "Spawns", "MovementIgnore"}
	local map = self.mm_groupChildren(workspace, except)
	map.Name = "Map"
	
	-- move barriers
	game:GetService("ServerStorage"):WaitForChild("Barriers").Parent = workspaceobjects
	
	-- ungroup WorkspaceObjects
	self.mm_ungroupChildren(workspaceobjects, workspace)
	
	self.canChangeMapMode = true
	ChangeHistoryService:SetWaypoint("Map Mode changed to Play.")
end

local nameToButton = {edit = mmeditButton, play = mmplayButton}
local function mm_click(name, noFunc)
	if not self.canChangeMapMode then return end
	if name == "edit" then
		mmeditButton:SetActive(true)
		mmplayButton:SetActive(false)
		if noFunc then return end
		task.spawn(self.mm_edit)
	else
		mmeditButton:SetActive(false)
		mmplayButton:SetActive(true)
		if noFunc then return end
		task.spawn(self.mm_play)
	end
end

-- [[ Version Handling ]]

local vh = require(script:WaitForChild("versionHandle"))

--

local function init()

	-- init version handling
	vh.init(self, vhpushupdatebutton, vhpullupdatebutton, vhunpackbutton, vhpackbutton)
	
	-- init map mode
	mmeditButton.Click:Connect(function() mm_click("edit") end)
	mmplayButton.Click:Connect(function() mm_click("play") end)
	mm_click(currentMapMode, true)
	
end

init()
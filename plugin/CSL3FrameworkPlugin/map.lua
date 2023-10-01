local ChangeHistoryService = game:GetService("ChangeHistoryService")

local map = {}
map.canChange = true
map.currentMode = false
map.editButton = false
map.playButton = false

function map.init(edit, play)
    map.currentMode = map.GetMode()
    map.editButton = edit
    map.playButton = play
    map.editButton.Click:Connect(function() map.Mode("Edit") end)
	map.playButton.Click:Connect(function() map.Mode("Play") end)
end

--

local modes = {
    Play = function()
        map.editButton:SetActive(false)
		map.playButton:SetActive(true)

        local workspaceobjects = workspace:FindFirstChild("WorkspaceObjects") or Instance.new("Model", workspace)
        workspaceobjects.Name = "WorkspaceObjects"

        local except = {"WorkspaceObjects", "CollisionBox", "Spawns", "MovementIgnore"}
        local _map = map.GroupService(workspace, workspace, except)
        _map.Name = "Map"
        
        if game.ServerStorage:FindFirstChild("Barriers") then game.ServerStorage.Barriers.Parent = game.ServerStorage end
        map.Ungroup(workspaceobjects, workspace)

        ChangeHistoryService:SetWaypoint("Map Mode changed to Play.")
    end,
    Edit = function()
        map.editButton:SetActive(true)
		map.playButton:SetActive(false)

        local except = {"Map", "CollisionBox", "Spawns", "MovementIgnore"}
        local workspaceobjects = map.GroupService(workspace, workspace, except)
        workspaceobjects.Name = "WorkspaceObjects"

        local _map = workspace:FindFirstChild("Map") or Instance.new("Model", workspace)
        _map.Name = "Map"

        if workspaceobjects:FindFirstChild("Barriers") then workspaceobjects.Barriers.Parent = game.ServerStorage end
        map.Ungroup(_map, workspace)
        
        ChangeHistoryService:SetWaypoint("Map Mode changed to Edit.")
    end
}

--@summary Change the "Map Mode"
function map.Mode(mode: string)
    assert(map.canChange, "Cannot Change Map right now!")
    assert(mode == "Edit" or mode == "Play", "Invalid MapMode!")
    assert(mode ~= map.currentMode, "MapMode already " .. tostring(mode) .. "!")
    map.canChange = false
    map.currentMode = mode
    modes[mode]()
    map.canChange = true
end

--@summary Get the Current "Map Mode"
function map.GetMode()
    return map.currentMode or ((workspace:FindFirstChild("Map") and workspace.Map:GetAttribute("IsMapMode")) and "Map" or "Edit")
end

--@summary Group all the Children of a Service. Specify ignore names.
--         Automatically ignores Terrains and Cameras.
function map.GroupService(service, whereTo, ignoreNameArray)
    local ignoreList = {}
    if ignoreNameArray then
        for _, v in ignoreNameArray do
			ignoreList[v] = v
		end
    end
	local model = Instance.new("Model")
	model.Parent = whereTo
	for _, v in pairs(service:GetChildren()) do
		if v == model or ignoreList[v.Name] then continue end
		if v:IsA("Terrain") or v:IsA("Camera") then continue end
		v.Parent = model
	end
	return model
end

--@summary Ungroup a grouped object.
function map.Ungroup(object, whereTo)
    for _, v in pairs(object:GetChildren()) do
		v.Parent = whereTo
	end
	object:Destroy()
end

return map
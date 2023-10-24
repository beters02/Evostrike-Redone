--	Service
local Lighting = game:GetService("Lighting")
local Service__ServerStorage		=	game:GetService("ServerStorage")
local Service__ChangeHistoryService	=	game:GetService("ChangeHistoryService")
local Service__Selection			=	game:GetService("Selection")

--	Plugin
local Toolbar					=	plugin:CreateToolbar("Bryces Map Saver")
local Button__SaveMap			=	Toolbar:CreateButton("Save Map", "Save the map","rbxassetid://12021289734")

--	RBXScriptSignal

Button__SaveMap.Click:Connect(function()

	--	Instance Saving

	--folder creation
	local Folder__Map		=	Instance.new("Folder")
	Folder__Map.Name		=	"Folder__Map"

	local Folder__Instance	=	Instance.new("Folder")
	Folder__Instance.Name	=	"Folder__Instance"

	--loop save
	for _, Child__Workspace in pairs(workspace:GetChildren()) do

		if Child__Workspace:IsA("Terrain") == false and Child__Workspace:IsA("Camera") == false then

			local Child__Workspace__Clone	=	Child__Workspace:Clone()

			Child__Workspace__Clone.Parent	=	Folder__Instance

		end

	end



	--	Terrain Saving

	local TerrainRegion				=	workspace.Terrain:CopyRegion(workspace.Terrain.MaxExtents)

	local Folder__Water__Properties	=	Instance.new("Folder")
	Folder__Water__Properties.Name	=	"Folder__Water__Properties"

	Folder__Water__Properties:SetAttribute("WaterColor", workspace.Terrain.WaterColor)
	Folder__Water__Properties:SetAttribute("WaterReflectance", workspace.Terrain.WaterReflectance)
	Folder__Water__Properties:SetAttribute("WaterTransparency", workspace.Terrain.WaterTransparency)
	Folder__Water__Properties:SetAttribute("WaterWaveSize", workspace.Terrain.WaterWaveSize)
	Folder__Water__Properties:SetAttribute("WaterWaveSpeed", workspace.Terrain.WaterWaveSpeed)

	local Folder__Material__Properties	=	Instance.new("Folder")
	Folder__Material__Properties.Name	=	"Folder__Material__Properties"


	for _, EnumItem__Material in pairs(Enum.Material:GetEnumItems()) do

		pcall(function()

			if workspace.Terrain:GetMaterialColor(EnumItem__Material) then

				Folder__Material__Properties:SetAttribute(EnumItem__Material.Name, workspace.Terrain:GetMaterialColor(EnumItem__Material))

			end

		end)

	end

    -- Lighting

    local Folder__Lighting = Instance.new("Folder")
    Folder__Lighting.Name = "Folder__Lighting"

    local lightings = {
        "Ambient",
        "Brightness",
        "ColorShift_Bottom",
        "ColorShift_Top",
        "EnvironmentDiffuseScale",
        "EnvironmentSpecularScale",
        "GlobalShadows",
        "OutdoorAmbient",
        "ShadowSoftness",
        "Technology",
        "GeographicLatitude",
        "ExposureCompensation"
    }

	Folder__Lighting:SetAttribute("MinutesAfterMidnight", game.Lighting:GetMinutesAfterMidnight())
    for _, v in pairs(lightings) do
        pcall(function() Folder__Lighting:SetAttribute(v, Lighting[v]) end)
    end

    for _, v in pairs(Lighting:GetChildren()) do
        v:Clone().Parent = Folder__Lighting
    end

	--	Parenting

    Folder__Lighting.Parent = Folder__Map
	Folder__Instance.Parent				=	Folder__Map
	Folder__Water__Properties.Parent	=	TerrainRegion
	Folder__Material__Properties.Parent	=	TerrainRegion
	TerrainRegion.Parent				=	Folder__Map
	Folder__Map.Parent					=	Service__ServerStorage

	Service__ChangeHistoryService:SetWaypoint("Map Saved")

	Service__Selection:Set({Folder__Map})


end)


--[[Button__LoadMap.Click:Connect(function()

	if #Service__Selection:Get() > 0 then

		local Folder	=	Service__Selection:Get()[1]

		if Folder:FindFirstChildWhichIsA("Folder") then

			for _, Child in pairs(Folder:FindFirstChildWhichIsA("Folder"):GetChildren()) do

				local Child__Clone	=	Child:Clone()
				Child__Clone.Parent	=	workspace

			end

		end


		if Folder:FindFirstChildWhichIsA("TerrainRegion") then

			if Folder:FindFirstChildWhichIsA("TerrainRegion"):FindFirstChild("Folder__Material__Properties") then

				for string__Material, Color3__Material in pairs(Folder:FindFirstChildWhichIsA("TerrainRegion"):FindFirstChild("Folder__Material__Properties"):GetAttributes()) do

					pcall(function()

						workspace.Terrain:SetMaterialColor(Enum.Material[string__Material], Color3__Material)

					end)

				end

			end

			if Folder:FindFirstChildWhichIsA("TerrainRegion"):FindFirstChild("Folder__Water__Properties") then

				for string__Water__Property, Water__Property in pairs(Folder:FindFirstChildWhichIsA("TerrainRegion"):FindFirstChild("Folder__Water__Properties"):GetAttributes()) do

					pcall(function()

						workspace.Terrain[string__Water__Property]	=	Water__Property

					end)

				end

			end

			local Vector3int16__Corner	= Vector3int16.new(

				-math.floor(Folder:FindFirstChildWhichIsA("TerrainRegion").SizeInCells.X / 2),
				-math.floor(Folder:FindFirstChildWhichIsA("TerrainRegion").SizeInCells.Y / 2),
				-math.floor(Folder:FindFirstChildWhichIsA("TerrainRegion").SizeInCells.Z / 2)

			)

			workspace:FindFirstChildWhichIsA("Terrain"):PasteRegion(Folder:FindFirstChildWhichIsA("TerrainRegion"), Vector3int16__Corner, false)

		end

	end

	Service__ChangeHistoryService:SetWaypoint("Map Loaded")

end)]]
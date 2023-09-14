local InsertService = game:GetService("InsertService")
local FrameworkModule = game:GetService("ReplicatedStorage"):WaitForChild("Framework")
local ServerStorage = game:GetService("ServerStorage")
local sp = game:GetService("StarterPlayer")

--[[ Configuration ]]
local _defaultVersion = "0.0.1"
local _versionInformationPackageID = 14586761573

local vh = {}

local function vh_seperateStringToChar(str)
	print(str)
	local new = {}
	for i = 1, str:len() do
		table.insert(new, str:sub(i,i))
	end
	return new
end

local function vh_convertVersionToNumber(verstr)

	verstr = string.gsub(verstr, "%.", "")
	local numstr = ""
	local ignore = true
	for i, v in pairs(vh_seperateStringToChar(verstr)) do
		if v == 0 then
			if ignore then continue end
		else
			if ignore then ignore = false end
			numstr = numstr .. v
		end
	end

	print(numstr)

	return tonumber(numstr)
end

function vh.init(self, vhpushupdate, vhpullupdate, vhunpackbutton, vhpackbutton)
    vhpushupdate.Click:Connect(function()
		if self.vh_isupdating then
			warn("Already updating!")
			return
		end

		if self.vh_isunpacking then
			warn("Already unpacking!")
			return
		end
		self.vh_isupdating = true
			
		local success, err = pcall(function()
			vh.click(self, "pushupdate")
		end)
		if not success then warn("Could not update! " .. err) end
		
		self.vh_isupdating = false
		return
	end)

	vhpullupdate.Click:Connect(function()
		if self.vh_isupdating then
			warn("Already updating!")
			return
		end

		if self.vh_isunpacking then
			warn("Already unpacking!")
			return
		end
		self.vh_isunpacking = true
			
		local success, err = pcall(function()
			vh.click(self, "pullupdate")
		end)
		if not success then warn("Could not unpack! " .. err) end
		
		self.vh_isunpacking = false
		return
	end)

	vhunpackbutton.Click:Connect(function()
		if self.vh_isupdating then
			warn("Already updating!")
			return
		end

		if self.vh_isunpacking then
			warn("Already unpacking!")
			return
		end
		self.vh_isunpacking = true
			
		local success, err = pcall(function()
			vh.click(self, "unpack")
		end)
		if not success then warn("Could not unpack! " .. err) end
		
		self.vh_isunpacking = false
		return
	end)

	vhpackbutton.Click:Connect(function()
		if self.vh_isupdating then
			warn("Already updating!")
			return
		end

		if self.vh_isunpacking then
			warn("Already unpacking!")
			return
		end
		self.vh_isupdating = true
			
		local success, err = pcall(function()
			vh.click(self, "pack")
		end)
		if not success then warn("Could not pack! " .. err) end
		
		self.vh_isupdating = false
		return
	end)
end

-- pulls current files and pushes them into a version model
function vh.pushUpdate(self)
	print('Update started! Check screen for GUI Prompt.')
	
	-- var
	local currversion = FrameworkModule:GetAttribute("Version") or "0.0.1"
	local newversion
	local packWithMap = 0
	local _conn = {}

	-- confirm update version from player
	local newconfirmclone = self.vhUpdateConfirmGui:Clone()
	
	_conn.update = newconfirmclone.Frame.TextButton.MouseButton1Click:Connect(function()
		local vnum = vh_convertVersionToNumber(newconfirmclone.Frame.TextBox.Text)
		print(vnum, "UPDATE")

		--if not num then num = vh_addVersion(0) end

		if not vnum then
			newconfirmclone:Destroy()
			_conn.update:Disconnect()
			return error("Could not complete update! Cancelling.")
		end
		newversion = newconfirmclone.Frame.TextBox.Text
	end)
	newconfirmclone.Parent = game:WaitForChild("CoreGui")
	
	local t = tick() + 10
	repeat task.wait() until tick() >= t or newversion -- 10 second timeout
	newconfirmclone:Destroy()
	_conn.update:Disconnect()

	-- confirm pack with map
	newconfirmclone = self.vhPackWithMapConfirmGui:Clone()

	_conn.yes = newconfirmclone.Frame.YesButton.MouseButton1Click:Connect(function()
		packWithMap = true
		_conn.no:Disconnect()
		_conn.yes:Disconnect()
	end)

	_conn.no = newconfirmclone.Frame.NoButton.MouseButton1Click:Connect(function()
		packWithMap = false
		_conn.yes:Disconnect()
		_conn.no:Disconnect()
	end)
	
	newconfirmclone.Parent = game:WaitForChild("CoreGui")
	
	t = tick() + 10
	repeat task.wait() until tick() >= t or type(packWithMap) == "boolean" -- 10 second timeout
	newconfirmclone:Destroy()
	
	FrameworkModule:SetAttribute("Version", newversion)

	-- pack folders
	print('Packing models...')

	-- check if there is already a model to overwrite
	local modelPackInto = false
	for i, v in pairs(ServerStorage:GetChildren()) do
		if not v:IsA("Model") then continue end
		if string.match(v.Name, "CSL^3 Framework") then
			print('Found Model to overwrite!')
			modelPackInto = v

			-- clear all models in model
			for _, child in pairs(v:GetChildren()) do
				if child:IsA("Model") then child:Destroy() end
			end

			break
		end
	end
	vh.pack(self, newversion, false, packWithMap, modelPackInto)

	print('Done! Check ServerStorage')
end

--[[
	@name			pullUpdate
	@summary		pulls files from a version model and pushes them into current files

					DESTROYS *ALL* CURRENT FILES
					*ignores*
						gamemode: bots spawns barriers
						game: lighting, workspace
	@return void
]]

-- 
function vh.pullUpdate(self)

	-- make sure we have a model that can be unpacked
	local currModel = vh.findVersionFile()

	-- first we pack all current items
	local curr = vh.pack(self, "0.0.1", true, true)
	curr.Name = "SSS"

	local leave = {}

	-- then we leave any files that need to not be overwritten
	for _, gm in pairs(curr.ServerScriptService.gamemode.class:GetChildren()) do

		-- bots, spawns, barriers
		for _, gmo in pairs({"Bots", "Spawns", "Barriers"}) do
			if gm:FindFirstChild(gmo) then
				if not leave[gm.Name] then leave[gm.Name] = {} end
				table.insert(leave[gm.Name], gm[gmo]) -- store in "leave" array to replace at the end
			end
		end
		
	end

	-- now we unpack
	vh.unpac(self)

	-- write gamemode "leave" old to new
	for gmname, gmtab in pairs(leave) do
		for _, obj in pairs(gmtab) do
			if not obj or not obj.Name then continue end
			if game:GetService("ServerScriptService").gamemode.class[gmname]:FindFirstChild(obj.Name) then
				game:GetService("ServerScriptService").gamemode.class[gmname][obj.Name]:Destroy()
			end
			obj.Parent = game:GetService("ServerScriptService").gamemode.class[gmname]
		end
	end

	-- replace current workspace with old
	for i, v in pairs(workspace:GetChildren()) do
		pcall(function()
			v:Destroy()
		end)
	end

	for i, v in pairs(curr.Workspace:GetChildren()) do
		v.Parent = workspace
	end

	-- replace current lighting with old
	for i, v in pairs(game:GetService("Lighting"):GetChildren()) do
		pcall(function()
			v:Destroy()
		end)
	end

	for i, v in pairs(curr.Lighting:GetChildren()) do
		v.Parent = game:GetService("Lighting")
	end

	-- destroy old
	currModel:Destroy()

	print('Update pulled!')
end

function vh.pack(self, vers: number, destroyAfter: boolean, packMap: boolean, modelPackInto: Model?)
	local model = modelPackInto or Instance.new("Model")
	model.Name = "CSL^3 Framework v" .. tostring(vers or "0.0.1")
	
	-- everything but starter player
	local grab = {
		game:GetService("Workspace"), game:GetService("Lighting"),
		game:GetService("MaterialService"), game:GetService("ReplicatedFirst"),
		game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService"),
		game:GetService("ServerStorage"), game:GetService("StarterGui"),
	}
	
	-- handle map stuff
	if self.currentMapMode ~= "play" then -- set play mode if not already
		self.mm_play()
	end

	-- starter player stuff
	local _spm = Instance.new("Model")
	_spm.Name = "StarterPlayer"
	_spm.Parent = model

	sp = game:GetService("StarterPlayer")

	local stcsuccess, err = pcall(function()
		sp.StarterCharacter:Clone().Parent = _spm
		if destroyAfter then sp.StarterCharacter:Destroy() end
	end)
	
	if not stcsuccess then
		warn("Could not pack startercharacter: " .. tostring(err))
	end
	
	for _, spmc in pairs({sp.StarterPlayerScripts, sp.StarterCharacterScripts}) do
		local _spmm = Instance.new("Model")
		_spmm.Name = spmc.Name
		_spmm.Parent = _spm
		for i, v in pairs(spmc:GetChildren()) do
			local success = pcall(function()
				v:Clone().Parent = _spmm
			end)
			if success and destroyAfter then
				game:GetService("Debris"):AddItem(v, 3)
				--v:Destroy()
			end
		end
	end

	-- general file stuff
	for si, servicec in pairs(grab) do
		local _m = Instance.new("Model")
		_m.Name = servicec.Name
		_m.Parent = model
		for i, v in pairs(servicec:GetChildren()) do
			if si == 1 and v.Name == "Map" and not packMap then -- Workspace Map Model
				continue
			end

			if si == 7 and string.match(v.Name, "CSL^3 Framework") then -- Ignore current Framework Model
				continue
			end

			local success = pcall(function()
				local _vc: Instance = v:Clone()
				for attname, attv in pairs(v:GetAttributes()) do
					_vc:SetAttribute(attname, attv)
				end
				_vc.Parent = _m
			end)

			if success and destroyAfter then
				v:Destroy()
			end
		end
	end
	
	-- finish
	model.Parent = game:GetService("ServerStorage")
	return model
end

function vh.unpac(self)
	local model = vh.findVersionFile()
	if not model then return end

	for i, v in pairs(model:GetChildren()) do
		if v:IsA("PackageLink") then continue end

		if v.Name == "StarterPlayer" then

			local stcsuccess, stcerr = pcall(function()
				v.StarterCharacter.Parent = sp
			end)

			if not stcsuccess then
				warn("Could not unpack StarterCharacter " .. tostring(stcerr))
			end

			sp.StarterCharacterScripts:ClearAllChildren()
			sp.StarterPlayerScripts:ClearAllChildren()

			self.mm_ungroupChildren(v.StarterCharacterScripts, sp.StarterCharacterScripts)
			self.mm_ungroupChildren(v.StarterPlayerScripts, sp.StarterPlayerScripts)

			v:Destroy()
			continue
		end

		self.mm_ungroupChildren(v, game[v.Name])
	end

	model:Destroy()

	print("Successfully Unpacked!")

end

function vh.click(self, name)
	print(name)
	if name == "pushupdate" then
		vh.pushUpdate(self)
	elseif name == "pullupdate" then
		vh.pullUpdate(self)
	elseif name == "unpack" then
		vh.unpac(self)
	elseif name == "pack" then
		vh.pack(self, "0_0_1", true, true)
	end
end

function vh.findVersionFile()
	local model = false
	for i, v in pairs(game:GetService("ServerStorage"):GetChildren()) do
		if string.match(v.Name, "CSL^3 Framework") then
			model = v
			break
		end
	end

	if not model then
		warn("Could not find stored model!")
		return false
	end

	return model
end

return vh
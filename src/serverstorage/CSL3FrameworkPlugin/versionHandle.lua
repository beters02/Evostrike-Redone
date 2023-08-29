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

--[[local function convertNumberToVersion(num)
	local _vstr = ""
	local _sep = vh_seperateStringToChar(tostring(num))
	for i = 1, 3 - tostring(num):len() do _vstr = _vstr .. "0_" end -- add zeros
	for i, v in pairs(_sep) do
		_vstr = _vstr .. tostring(v) .. "_" -- add other numbers
		if i ~= #_sep then -- add trail if not last number
			_vstr = _vstr .. "_"
		end
	end

	print(_vstr, "STRING")
	return _vstr
end

local function vh_addVersion(add)

	local vers = FrameworkModule:GetAttribute("Version")
	if not vers then
		warn("Cannot add version, No version attribute set on Framework!")
		return false
	end

	print(vers)

	local _vnum = vh_convertVersionToNumber(FrameworkModule:GetAttribute("Version"))
	print(_vnum, "ADD")

	if _vnum then
		local _vstr = ""
		for i = 1, 3 - tostring(add+_vnum):len() do _vstr = _vstr .. "0_" end -- add zeros
		for i = 1, tostring(_vnum):len() do _vstr = _vstr .. tostring(_vnum) .. "_" end -- add other numbers
		print(_vstr, "STRING")
		return _vstr
	end
	
	return false
end]]

function vh.update(self)
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
end

function vh.unpac(self)
	print('yuh')

	local model = false
	for i, v in pairs(game:GetService("ServerStorage"):GetChildren()) do
		if string.match(v.Name, "CSL^3 Framework") then
			model = v
			break
		end
	end

	if not model then
		warn("Could not find stored model!")
		return
	end

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
	if name == "update" then
		vh.update(self)
	elseif name == "unpack" then
		vh.unpac(self)
	elseif name == "pack" then
		vh.pack(self, "0_0_1")
	end
end

function vh.init(self, vhupdatebutton, vhunpackbutton, vhpackbutton)
    vhupdatebutton.Click:Connect(function()
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
			vh.click(self, "update")
		end)
		if not success then warn("Could not update! " .. err) end
		
		self.vh_isupdating = false
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
		
		self.vh_isunpacking= false
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

return vh
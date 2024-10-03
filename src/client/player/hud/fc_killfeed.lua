local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))

local player = game:GetService("Players").LocalPlayer

local function getWeaponIconID(weapon)
	return Framework.Service.WeaponService.Weapon[weapon].Assets.Images.iconEquipped.Image
end

local killfeed = {}
killfeed.__index = killfeed

function killfeed.init(self)
    local _n = {}
    _n.frame = self.killfr
	_n.itemframe = _n.frame:WaitForChild("ItemFrame")
	_n.currentItems = {}
	_n.upLength = self.upLength or 5
	_n.yours = self.yours
	if self.yours then
		function _n:setKillfeedTexts(item, killer, killed)
			item:WaitForChild("KillText").Text = "Killed " .. tostring(killed.Name)
		end
	else
		function _n:setKillfeedTexts(item, killer, killed)
			item:WaitForChild("KillerName").Text = killer.Name
			item:WaitForChild("KilledName").Text = killed.Name
			if killer.Name == player.Name then
				item.KillerName.TextStrokeColor3 = item:GetAttribute("YouKilledStrokeColor")
				item.KillerName.DefaultGradient.Enabled = false
				item.KillerName.YourGradient.Enabled = true
			end
		end
	end
    return setmetatable(_n, killfeed)
end

--

function killfeed:addItem(killer, killed)
	local item = self.itemframe:Clone()
	
	if #self.currentItems > 0 then
		if #self.currentItems == 3 then
			removeItemFromIndex(self, 1, true)
		end
		
		for i, v in pairs(self.currentItems) do
			local currPos = v.frame.Position
			local tween = TweenService:Create(v.frame, TweenInfo.new(0.3), {Position = UDim2.fromScale(currPos.X.Scale, currPos.Y.Scale + (self.yours and 0.25 or 0.163))})
			tween:Play()
		end
	end
	
	self:setKillfeedTexts(item, killer, killed)
	item.Visible = true
	item.GroupTransparency = 1

	local character

	if killed:IsA("Player") then
		character = killed.Character
	else
		character = killed
	end

	if not self.yours then
		if character:GetAttribute("DiedToHeadshot") then
			item:WaitForChild("WeaponIcon").Position = UDim2.fromScale(0.37, 0.201)
			item:WaitForChild("Icon1").Visible = true
		else
			item:WaitForChild("WeaponIcon").Position = UDim2.fromScale(0.429, 0.201)
			item:WaitForChild("Icon1").Visible = false
		end

		local weaponUsed = killed:GetAttribute("WeaponUsedToKill")
		if weaponUsed then
			item:WaitForChild("WeaponIcon").Image = getWeaponIconID(weaponUsed)
		end
	end

	local index = #self.currentItems + 1
	local newTable = {frame = item, tweenIn = nil, tweenOut = nil}
	newTable.tweenIn = TweenService:Create(item, TweenInfo.new(0.4), {GroupTransparency = 0})
	newTable.tweenOut = TweenService:Create(item, TweenInfo.new(0.6), {GroupTransparency = 1})
	table.insert(self.currentItems, index, newTable)
	
	item.Parent = self.frame
	newTable.tweenIn:Play()
	
	task.delay(self.upLength, function()
		if item then
			removeItemFromFrame(self, item)
		end
	end)
end

function removeItemFromFrame(self, frame, instant)
	local itemTable, index = getTabFromFrame(self, frame)
	if not itemTable then return end
	if not instant then
		itemTable.tweenOut:Play()
		task.wait(0.61)
		itemTable, index = getTabFromFrame(self, frame) -- regrab frame index
		if not itemTable then return end
	end
	itemTable.frame:Destroy()
	table.remove(self.currentItems, index)
end

function removeItemFromIndex(self, index, instant) -- slightly unsafe if not instant
	local itemTable = self.currentItems[index]
	if not instant then
		itemTable.tweenOut:Play()
		task.wait(0.61)
	end
	itemTable.frame:Destroy()
	table.remove(self.currentItems, index)
end

function getTabFromFrame(self, frame)
	for i, v in pairs(self.currentItems) do
		if v.frame == frame then
			return v, i
		end
	end
end

return killfeed
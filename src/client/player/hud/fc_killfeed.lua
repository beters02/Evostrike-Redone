local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = game:GetService("Players").LocalPlayer

local killfeed = {}
killfeed.__index = killfeed

function killfeed.init(self)
    local _n = {}
    _n.frame = self.killfr
    _n.itemframe = _n.frame:WaitForChild("ItemFrame")
	_n.currentItems = {}
	_n.upLength = self.upLength or 5
	if self.yours then
		function _n:setKillfeedTexts(item, killer, killed)
			item:WaitForChild("KillText").Text = "Killed " .. tostring(killed.Name)
		end
	else
		function _n:setKillfeedTexts(item, killer, killed)
			item:WaitForChild("KillerName").Text = killer.Name
			item:WaitForChild("KilledName").Text = killed.Name
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
			local tween = TweenService:Create(v.frame, TweenInfo.new(0.3), {Position = UDim2.fromScale(currPos.X.Scale, currPos.Y.Scale + 0.33)})
			tween:Play()
		end
	end
	
	self:setKillfeedTexts(item, killer, killed)
	item.Visible = true
	item.GroupTransparency = 1
	
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
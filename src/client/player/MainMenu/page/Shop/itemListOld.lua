local Shop = {}

-- [[ ITEM LIST CONTAINER ]]
function Shop:SetItemListContainer(containerStr: "Collections" | "Skins")
    self:CloseItemList()
    self:_DisconnectItemList()

    if containerStr == "Collections" then
        self.itemListContainer = self.ilc_Collections

        self.ilc_Cases.Visible = false
        self.ilc_Skins.Visible = false
        self.ilc_Collections.Visible = true
    end
end

-- [[ ITEM LIST ]]
function Shop:OpenItemList(frame, ignoreDisconnect)
    if self.itemListVar.OpenListName == frame.Name then
        return
    end
    self.Location.ItemListContainer_Skins:SetAttribute("LastItemList", self.itemListVar.OpenListName)
    self.Location.ItemListContainer_Skins:SetAttribute("CurrentItemList", frame.Name)
    self.itemListVar.OpenListName = frame.Name
    self.itemListFrame.Visible = false

    frame.Visible = true
    self.itemListFrame = frame
    self:_ConnectItemList(frame)
end

function Shop:CloseItemList() -- back to default, MainList
    if self.itemListVar.OpenListName ~= "MainList" then
        self.Location.ItemListContainer_Skins:SetAttribute("LastItemList", self.itemListVar.OpenListName)
        self.itemListFrame.Visible = false
        self.itemListVar.OpenListName = "MainList"
    end
    self.itemListFrame = self.itemListDefaultFrame
    self.itemListFrame.Visible = true
    self:_ConnectItemList(self.itemListFrame)
    self.Location.ItemListContainer_Skins:SetAttribute("CurrentItemList", "MainList")
end

function Shop:OpenLastItemList()
    local curr, last = self.Location.ItemListContainer_Skins:GetAttribute("CurrentItemList"), self.Location.ItemListContainer_Skins:GetAttribute("LastItemList")
    if curr == last or curr == "MainList" then return end
    if last == "MainList" then
        self:CloseItemList()
    else
        self:OpenItemList(self.Location.ItemListContainer_Skins[last])
    end
    self.Location.ItemListContainer_Skins:SetAttribute("CurrentItemList", last)
end

function Shop:_ConnectItemList(listFrame)
    local isMain = listFrame.Name == "MainList"

    if isMain then
        self.Location.ItemListContainer_Skins.BackButton.Visible = false
    else
        if self.itemListConns.Back then
            self.itemListConns.Back:Disconnect()
        end
        local backConnection = self.Location.ItemListContainer_Skins.BackButton.MouseButton1Click:Connect(function()
            self:OpenLastItemList()
        end)
        self.Location.ItemListContainer_Skins.BackButton.Visible = true
        self.itemListConns.Back = backConnection
    end

    self:_DelayDisconnectList(#self.itemListConns)
    
    for _, item in pairs(listFrame:GetChildren()) do
        if not item:IsA("Frame") then
            continue
        end

        local button = item:WaitForChild("TextButton")
        local connection = button.MouseButton1Click:Connect(function()
            if item.Parent.Name == "MainList" then
                local corrList = string.gsub(item.Name, "ButtonFrame_", "")
                corrList = item.Parent.Parent["ItemList_" .. corrList]
                self:OpenItemList(corrList, true)
            else
                local displayName = item:GetAttribute("ItemDisplayName") or string.upper(string.gsub(item.Name, "ItemList_", ""))
                self:OpenItemDisplay(item:GetAttribute("Item"), displayName)
            end
        end)

        table.insert(self.itemListConns, connection)
    end
end

function Shop:_DisconnectItemList()
    for _, v in pairs(self.itemListConns) do
        v:Disconnect()
    end
    self.itemListConns = {}
end

function Shop:_DelayDisconnectList(total)
    if total > 0 then
        task.delay(0.1, function()
            for i = 1, #self.itemListConns do
                self.itemListConns[i] = nil
            end
        end)
    end
end

return Shop
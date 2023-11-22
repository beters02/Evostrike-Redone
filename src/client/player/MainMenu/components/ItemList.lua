-- [[ Page Component ItemList ]]
--[[
    To create an ItemList:
    
    Create a Frame for your ItemList named ' ItemList_ {itemListName} '
    and insert a child frame named "Page_Main".
    Page frame must have a child frame named "List".

    Add your Items as Frames named ' ItemFrame_ {itemFrameName} ' as children of your Page's List Frame
    ItemFrames must have a child  TextButton or ImageButton named "Button"
    --ItemFrames must also have an attribute called "Item", with the value being the PlayerData skin item it purchases.
]]

export type ClickedAction = "PageLink" | "ItemDisplay"

local ItemList = {}
ItemList.__index = ItemList

-- @summary Initialize a pre-made ItemList Frame as an ItemList Object
--          Remember to Disconnect ItemList when not in use.
function ItemList.init(mainMenuPageModule, frame)
    local self = setmetatable({pages = {}, connections = {}, Enabled = false, Frame = frame, mmPageModule = mainMenuPageModule}, ItemList)
    local mainPage = frame:FindFirstChild("Page_Main")
    assert(mainPage, "Item List does not contain a Page_Main")
    assert(mainPage:FindFirstChild("List"), "Page_Main does not contain List Frame")
    return self
end

function ItemList:Enable()
    self.Enabled = true
    self.Frame.Visible = true
    self.connections.back = self.Frame:WaitForChild("BackButton").MouseButton1Click:Connect(function()
        if self.Frame.BackButton.Visible then
            local last = self.Frame:GetAttribute("LastPage")
            self:ClosePage(self.Frame:GetAttribute("CurrentPage"))
            self:OpenPage(last)
        end
    end)
    self:InitPages()
    self:OpenPage("Page_Main")
end

function ItemList:Disable()
    self.Enabled = false
    self.Frame.Visible = false
    self:Disconnect()
end

function ItemList:OpenPage(pageName)
    self.Frame.BackButton.Visible = pageName ~= "Page_Main"
    self.Frame:SetAttribute("CurrentPage", pageName)
    self:GetPage(pageName).frame.Visible = true
end

function ItemList:ClosePage(pageName)
    self.Frame:SetAttribute("LastPage", pageName)
    self:GetPage(pageName).frame.Visible = false
end

function ItemList:GetPage(pageName)
    return self.pages[pageName]
end

--

function ItemList:InitPages()
    local itemClicked = {
        PageLink = function(listPage, itemFrame)
            self:ClosePage(listPage.Name)
            self:OpenPage(itemFrame:GetAttribute("PageLink"))
        end,
        ItemDisplay = function(_, itemFrame)
            self.mmPageModule:OpenItemDisplay(itemFrame:GetAttribute("Item"), itemFrame:GetAttribute("ItemDisplayName"))
        end
    }
    for _, pageFrame in pairs(self.Frame:GetChildren()) do
        if not pageFrame:IsA("Frame") or not string.match(pageFrame.Name, "Page") then
            continue
        end

        local pageObject = {frame = pageFrame, connections = {}}
        pageObject.ItemClicked = function(itemFrame)
            if not pageFrame.Visible then
                return
            end
            itemClicked[pageFrame:GetAttribute("ClickedAction")](pageFrame, itemFrame)
        end

        -- init Page ItemFrames
        for _, itemFrame in pairs(pageFrame.List:GetChildren()) do
            if not itemFrame:IsA("Frame") or not string.match(itemFrame.Name, "ItemFrame_") then
                continue
            end
            table.insert(pageObject.connections, itemFrame.Button.MouseButton1Click:Connect(function() pageObject.ItemClicked(itemFrame) end))
        end

        pageFrame.Visible = false
        self.pages[pageFrame.Name] = pageObject
    end
end

function ItemList:Disconnect()
    for _, v in pairs(self.pages) do
        for _, conn in pairs(v.connections) do
            conn:Disconnect()
        end
    end
end

return ItemList
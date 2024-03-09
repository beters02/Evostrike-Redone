local gui = script:WaitForChild("Gui")
local main = gui:WaitForChild("MainFrame")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local UIState = require(Framework.Module.States):Get("UI")

--local remoteEvent = script:WaitForChild("Events"):WaitForChild("RemoteEvent")
local buyMenuEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BuyMenuSelected")
local popupText = require(gui:WaitForChild("BuyMenuPopupText"))
local clickDebounce = tick()
local player = game:GetService("Players").LocalPlayer

local WeaponService = Framework.Service.WeaponService
local AbilityService = Framework.Service.AbilityService

local MainFrame = gui:WaitForChild("MainFrame")
local AbilityFrame = MainFrame:WaitForChild("AbilityMiddleFrame")
local AbilityFrames = {AbilityFrame:WaitForChild("Movement"), AbilityFrame:WaitForChild("Utility")}

local WeaponFrame = MainFrame:WaitForChild("GunMiddleFrame")
local WeaponFrames = {WeaponFrame:WaitForChild("Pistols"), WeaponFrame:WaitForChild("Rifles")}

local function doWeaponFrames()
	for _, catFrame in pairs(WeaponFrames) do
		for _, frame in pairs(catFrame.ContentFrame:GetChildren()) do
			if not frame:IsA("Frame") then continue end
			local module = WeaponService.Weapon:FindFirstChild(string.lower(frame.Name))
			if not module then warn("Could not find weapon icon for " .. tostring(frame.Name)) continue end
			frame:WaitForChild("ImageButton").Image = module.Assets.Images.iconEquipped.Image
		end
	end
end

local function doAbilityFrames()
	for _, catFrame in pairs(AbilityFrames) do
		for _, frame in pairs(catFrame.ContentFrame:GetChildren()) do
			if not frame:IsA("Frame") then continue end
			local module = AbilityService.Ability:FindFirstChild(frame.Name)
			if not module then warn("Could not find ability icon for " .. tostring(frame.Name) .. " AbilityFrames are caps sensitive, could that be it?") continue end
			frame:WaitForChild("ImageButton").Image = module.Assets.Images.Icon.Image
		end
	end
end

task.spawn(doWeaponFrames)
task.spawn(doAbilityFrames)

local buttons = {
    abilityMiddleFrame = {},
    gunMiddleFrame = {},
    menuButtons = {
        gun = main:WaitForChild("GunMenuButton"),
        ability = main:WaitForChild("AbilityMenuButton"),
        back = main:WaitForChild("BackButton")
    }
}
local connections = {}

function init()
    for _, v in pairs(main:WaitForChild("AbilityMiddleFrame"):GetDescendants()) do
        if not v:IsA("ImageButton") then continue end
        v.Modal = false
        table.insert(buttons.abilityMiddleFrame, v)
    end
    for _, v in pairs(main:WaitForChild("GunMiddleFrame"):GetDescendants()) do
        if not v:IsA("ImageButton") then continue end
        v.Modal = false
        table.insert(buttons.gunMiddleFrame, v)
    end
end

local BuyMenu = {}

function BuyMenu:Enable(uiContainer)
    

    -- connect open
    game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
        if gp or player:GetAttribute("Typing") then return end
        if input.KeyCode == Enum.KeyCode.B then
            if gui.Enabled then
                self:Close()
                UIState:removeOpenUI("BuyMenu")
            else
                if UIState:getOpenUI("MainMenu") then return end
                self:Open()
                UIState:addOpenUI("BuyMenu", gui, true)
            end
        end
    end)

    --@run
    script.Name = "BuyMenuScript"
    gui.Name = "BuyMenu"
    --gui.Parent = uiContainer
end

function BuyMenu:Open()

    if gui.Enabled then
        return
    end

    gui.Enabled = true

    -- connect ability buttons
    for _, v in pairs(buttons.abilityMiddleFrame) do
        v.Modal = true
        connections[v.Parent.Name.."Clicked"] = v.MouseButton1Click:Connect(function()
            local slot = v.Parent.Parent.Parent.Name == "Movement" and "primary" or "secondary"
            buyMenuEvent:FireServer("AbilitySelected", v.Parent.Name, slot)
            popupText.burst("Selected " .. v.Parent.Name .. "! Press ESC and Reset Character to get ability.", 2)
        end)
    end

    -- connect weapon buttons
    for i, v in pairs(buttons.gunMiddleFrame) do
        v.Modal = true
        connections[v.Parent.Name .. "Clicked"] = v.MouseButton1Click:Connect(function()
            local slot = v.Parent.Parent.Parent.Name == "Rifles" and "primary" or "secondary"
            buyMenuEvent:FireServer("WeaponSelected", v.Parent.Name, slot)
            popupText.burst("Selected " .. v.Parent.Name .. "! Press ESC and Reset Character to get weapon.", 2)
        end)
    end

    -- connect page buttons
    buttons.menuButtons.gun.Modal = true
    connections["GunMenuButtonClicked"] = buttons.menuButtons.gun.MouseButton1Click:Connect(function()
        if tick() < clickDebounce then return end
        clickDebounce = tick() + 0.1
        main:WaitForChild("GunMiddleFrame").Visible = true
        main:WaitForChild("AbilityMiddleFrame").Visible = false
    end)

    buttons.menuButtons.ability.Modal = true
    connections["AbilityMenuButtonClicked"] = buttons.menuButtons.ability.MouseButton1Click:Connect(function()
        if tick() < clickDebounce then return end
        clickDebounce = tick() + 0.1
        main:WaitForChild("GunMiddleFrame").Visible = false
        main:WaitForChild("AbilityMiddleFrame").Visible = true
    end)

    -- connect back
    buttons.menuButtons.back.Modal = true
    connections["BackButtonClicked"] = buttons.menuButtons.back.MouseButton1Click:Connect(function()
        if tick() < clickDebounce then return end
        clickDebounce = tick() + 0.1
        gui.Enabled = false
        UIState:removeOpenUI("BuyMenu")
    end)
end

function BuyMenu:Close()

    if not gui.Enabled then
        return
    end

    gui.Enabled = false
    for i, v in pairs(connections) do
        v:Disconnect()
    end
    connections = {}

    for _, v in pairs(buttons) do
        if type(v) == "table" then
            for _, b in pairs(v) do
                b.Modal = false
            end
            continue
        end
        v.Modal = false
    end
end

return BuyMenu
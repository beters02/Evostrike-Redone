local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local Strings = require(Framework.Module.lib.fc_strings)
local VMSprings = require(Framework.Module.lib.c_vmsprings)
local Math = require(Framework.Module.lib.fc_math)

local Ability = {}
local Types = require(script.Parent.Types)
local Tables = require(game.ReplicatedStorage:WaitForChild("lib").fc_tables)
local Grenade = require(script:WaitForChild("Grenade"))
Ability.__index = Ability

function Ability.new(module: ModuleScript)

    local self = Tables.clone(require(module))
    if self.Configuration.isGrenade then
        for i, v in pairs(Grenade) do
            if not self[i] then
                self[i] = v
            end
        end
    end
    self = setmetatable(self, Ability)

    self.Name = self.Configuration.name
    self.Slot = self.Configuration.inventorySlot
    self.Module = module

    self.Variables = {
        Uses = self.Configuration.uses,
        OnCooldown = false
    }

    self.Player = Players.LocalPlayer
    self.Character = self.Player.Character
    self.Humanoid = self.Character:WaitForChild("Humanoid")
    self.Viewmodel = workspace.CurrentCamera:WaitForChild("viewModel")
    self.Options = self.Configuration
    self.Frame = self.Player.PlayerGui:WaitForChild("HUD").AbilityBar:WaitForChild(Strings.firstToUpper(self.Options.inventorySlot))
    self.Icon = self.Frame:WaitForChild("IconImage")
    self.Key = ""
    self.Animations = {}

    if self.Options.useCameraRecoil then
        self:InitCameraRecoil()
    end

    if self.Module.Assets:FindFirstChild("Animations") then
        for _, v in pairs(self.Module.Assets.Animations:GetChildren()) do
            if string.match(v.Name, "Server") then
                self.Animations[string.lower(v.Name)] = self.Player.Character.Humanoid.Animator:LoadAnimation(v)
            else
                self.Animations[string.lower(v.Name)] = self.Viewmodel.AnimationController:LoadAnimation(v)
            end
        end
    end

    --hud
    self.Icon.Image = self.Module.Assets.Images.Icon.Texture
    self.Icon.ImageTransparency = 0
    self.Icon.ImageColor3 = self.Frame:GetAttribute("EquippedColor")
    self.Icon.Visible = true
    self.Frame.Visible = true

    return self :: Types.Ability
end

--@final
--@summary The Ability's Core Use function. The first function that runs when the Use key is pressed, not recommended to be changed.
function Ability:UseCore()
    if self.Variables.Uses <= 0 or self.Variables.OnCooldown then
        return
    end
    self.Variables.Uses -= 1
    self:Cooldown()

    if self.Options.useCameraRecoil then
        task.spawn(function() self:UseCameraRecoil() end)
    end

    self:Use()
end

--@summary The Ability's custom Use function. If any extra functionality is wanted on the Use, it's recommended to add it here.
function Ability:Use()
end

--@summary Start the Ability's cooldown
function Ability:Cooldown(): thread
    self.Variables.OnCooldown = true
    return task.spawn(function()
        self:SetIconColorEquipped(false)

        for i = self.Options.cooldownLength, 0, -1 do
            if i == 0 then
                self.Variables.OnCooldown = false
                self.Frame.Key.Text = Strings.convertFullNumberStringToNumberString(self.Key)
                self:SetIconColorEquipped(true)
                break
            end

            self.Frame.Key.Text = tostring(i)
            task.wait(1)
        end
    end)
end

--@summary Set the Ability's HUD Frame to equipped or unequipped
function Ability:SetIconColorEquipped(equipped)
    self.Frame.IconImage.ImageColor3 = equipped and self.Frame:GetAttribute("EquippedColor") or self.Frame:GetAttribute("UnequippedColor")
end

--@summary Stop All Playing Ability Animations
function Ability:StopAnimations(fadeTime: number?)
    for i, v in pairs(self.Animations) do
        if v.IsPlaying then
            v:Stop(fadeTime or 0)
        end
    end
end

--[[ CAMERA RECOIL ]]

--@summary Initialize Camera Recoil Springs
function Ability:InitCameraRecoil()
    self.Variables.cameraRecoil = true
    self.Variables.cameraSpring = VMSprings:new(self.Options.useCameraRecoil.mass, self.Options.useCameraRecoil.force, self.Options.useCameraRecoil.damp, self.Options.useCameraRecoil.speed)
    self.cameraRecoilUpdate = RunService.RenderStepped:Connect(function(dt)
        local update = self.Variables.cameraSpring:update(dt)
        workspace.CurrentCamera.CFrame *= CFrame.Angles(update.X, update.Y, update.Z)
    end)
end

--@summary Fire the Camera Recoil Springs
function Ability:UseCameraRecoil()

    -- parse absr
    local _parse = {self.Options.useCameraRecoil.up, self.Options.useCameraRecoil.side, self.Options.useCameraRecoil.shake}
    for i, v in pairs(_parse) do
        if type(v) == "string" then
            local _parsedStr = Strings.getParsedStringContents(v)
            if _parsedStr.action == "absr" then
                _parse[i] = Math.absr(_parsedStr.numbers[1])
            elseif _parsedStr.action == "rtabsr" then
                _parse[i] = Math.absr(math.random(_parsedStr.numbers[1] * 100, _parsedStr.numbers[2] * 100)/100)
            elseif _parsedStr.action == "r" then
                _parse[i] = math.random(_parsedStr.numbers[1] * 100, _parsedStr.numbers[2] * 100)/100
            end
        end
    end

    -- shoves
    local shove = Vector3.new(_parse[1], _parse[2], _parse[3])
    self.Variables.cameraSpring:shove(shove)
    task.delay(self.Options.useCameraRecoil.downDelay or 0.07, function()
        self.Variables.cameraSpring:shove(-shove)
    end)
end

--@summary Disconnect the Camera Recoil Connections.
function Ability:DisconnectCameraRecoil()
    self.cameraRecoilUpdate:Disconnect()
end

--@summary Create an Equip Animation Return Spring
function Ability:CreateEquipReturnSpring()

    --
    --
    -- did I write this piece of code when I was in a hurry to leave for work in 20 minutes?
    
    

    -- maybe.

    if self.Options.throwFinishSpringShove then -- create return spring if necessary
        local viewmodelModule = require(game:GetService("Players").LocalPlayer.Character:WaitForChild("ViewmodelScript").m_viewmodel)
        local function vmInit()
            local spring = VMSprings:new(4, 40, 4, 3)
            self.Variables._equipFinishCustomSpring = viewmodelModule:addCustomSpring(self.name .. "_EquipFinish", true, spring, self.Options.throwFinishSpringShove or Vector3.one,
            function()
                spring:shove(self.Options.throwFinishSpringShove or Vector3.one)
            end,
            function(vm, dt)
                local updated = spring:update(dt)
                vm.vmhrp.CFrame *= CFrame.new(updated.X, updated.Y, updated.Z)
            end)
        end
        if not viewmodelModule.storedClass then
            task.spawn(function()
                local t = tick() + 2
                if not viewmodelModule.storedClass then repeat task.wait() until viewmodelModule.storedClass or tick() >= t end
                if viewmodelModule.storedClass then
                    vmInit()
                end
            end)
        else
            vmInit()
        end
    end
end

return Ability
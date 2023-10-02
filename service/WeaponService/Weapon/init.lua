local Weapon = {}
Weapon.__index = Weapon

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage:WaitForChild("Framework"))
local Tables = require(ReplicatedStorage.lib.fc_tables)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local States = require(Framework.Module.m_states)
local UIState = States.State("UI")
local Types = require(script.Parent.Types)
local SoundModule = require(Framework.Module.Sound)
local SharedWeaponFunctions = require(Framework.Module.shared.weapon.fc_sharedWeaponFunctions)
local PlayerData = require(Framework.Module.shared.PlayerData.m_clientPlayerData)
local Strings = require(Framework.Module.lib.fc_strings)
local DiedBind = Framework.Module.EvoPlayer.Events.PlayerDiedBindable
local weaponWallbangInformation = require(ReplicatedStorage.Services.WeaponService.Shared).WallbangMaterials

function Weapon.new(weapon: string, tool: Tool)
    local weaponModule = require(ReplicatedStorage.Services.WeaponService):GetWeaponModule(weapon)
    local self = Tables.clone(require(weaponModule))
    self.Name = weapon
    self.Tool = tool
    self.Options = self.Configuration
    self.Slot = self.Configuration.inventorySlot
    self.Connections = {}
    self.Variables = {equipped = false, equipping = false, firing = false, reloading = false, inspecting = false, mousedown = false, fireScheduled = false, fireScheduleCancelThread = false,
    fireDebounce = false, currentBullet = 1, accumulator = 0, fireLoop = false, nextFireTime = tick(), lastFireTime = tick(), scoping = false, rescope = false, scopeTweens = false, scopedWhenShot = false}
    if self.Options.ammo then
        self.Variables.ammo = {magazine = self.Options.ammo.magazine, total = self.Options.ammo.total}
    end
    self.ClientModel = tool:WaitForChild("ClientModelObject").Value
    self.Viewmodel = workspace.CurrentCamera:WaitForChild("viewModel")
    self.Player = game:GetService("Players").LocalPlayer
    self.Character = self.Player.Character
    self.Humanoid = self.Character:WaitForChild("Humanoid")
    self.Module = weaponModule
    self.RemoteFunction = self.Tool.WeaponRemoteFunction
    self.ServerEquipEvent = self.Tool.WeaponServerEquippedEvent
    self.RemoteEvent = self.Tool.WeaponRemoteEvent
    self.CameraObject = require(ReplicatedStorage.Services.WeaponService.WeaponCamera).new(weapon)
    self.Variables.CrosshairModule = require(self.Character:WaitForChild("CrosshairScript"):WaitForChild("m_crosshair"))

    if self.init then
        self:init()
    end

    if string.lower(self.Name) == "knife" then
        self.Assets = self.Module.Assets[self.ClientModel:GetAttribute("SkinModel")]
    else
        self.Assets = self.Module.Assets
    end

    -- init weapon controller
    local controllermodule = require(self.Character:WaitForChild("WeaponController").Interface)
    local controller = controllermodule.currentController
    if not controller then
        repeat controller = controllermodule.currentController until controller
    end
    controller = controller :: Types.WeaponController
    self.Controller = controller

    -- init animations
	self.Animations = {client = {}, server = {}}
	for _, client in pairs(self.Assets.Animations:GetChildren()) do
		-- init server animations
		if client.Name == "Server" then
			for _, server in pairs(client:GetChildren()) do
				self.Animations.server[server.Name] = self.Humanoid.Animator:LoadAnimation(server)
			end
			continue
		elseif client.ClassName ~= "Animation" then continue end
		self.Animations.client[client.Name] = self.Viewmodel.AnimationController:LoadAnimation(client)
	end

    -- init hud
	self.Variables.weaponBar = self.Player.PlayerGui:WaitForChild("HUD").WeaponBar
	self.Variables.weaponFrame = self.Variables.weaponBar:WaitForChild(Strings.firstToUpper(self.Options.inventorySlot))
	self.Variables.infoFrame = self.Player.PlayerGui.HUD.InfoCanvas.MainFrame.WeaponFrame

    if self.Options.scope then
        Weapon.ScopeInit(self)
    end

	-- init icons
	self.Variables.weaponIconEquipped = self.Variables.weaponFrame:WaitForChild("EquippedIconLabel")
	self.Variables.weaponIconEquipped.Image = self.Assets.Images.iconEquipped.Image

	-- key
	self.Variables.weaponBar.SideBar[self.Options.inventorySlot .. "Key"].Text = Strings.convertFullNumberStringToNumberString(self.Controller.Keybinds[self.Slot .. "Weapon"])

	-- connect key changed bind for hud elements
    self.Connections["KeybindChanged"] = PlayerData:Changed("options.keybinds." .. self.Slot .. "Weapon", function(new)
        self.Variables.weaponBar.SideBar[self.Options.inventorySlot .. "Key"].Text = Strings.convertFullNumberStringToNumberString(new)
    end)

	-- enable
	self.Variables.weaponFrame.Visible = true

    -- connect equip & unequip
    self.Connections.Equip = self.Tool.Equipped:Connect(function()
        self:Equip()
    end)

    self.Connections.Unequip = self.Tool.Unequipped:Connect(function()
        self.Controller:UnequipWeapon(self.Slot)
    end)

    

    -- hide server model
    for _, v in pairs(self.Tool:WaitForChild("ServerModel"):GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Texture") then
			v.Transparency = 1
		end
	end

    self = setmetatable(self, Weapon)
    self:SetIconEquipped(false)
    return self
end

function Weapon:Equip()
    if self.Tool:GetAttribute("IsForceEquip") then
		self.Tool:SetAttribute("IsForceEquip", false)
	else
		if self.Player:GetAttribute("Typing") then return end
		if self.Player.PlayerGui.MainMenu.Enabled then return end
        if UIState:hasOpenUI() then return end
	end

	-- enable weapon icon
    self:SetIconEquipped(true)

    task.spawn(function()
        if string.lower(self.Name) == "knife" then
            self:PlaySound("Equip")
            self:SetInfoFrame("knife")
        else
            self:SetInfoFrame("gun")
        end
    end)

	-- var
    self.Variables.forcestop = false
    self.Variables.equipping = true
	States.SetStateVariable("PlayerActions", "weaponEquipping", true)
	States.SetStateVariable("PlayerActions", "weaponEquipped", self.Name)

	-- process equip animation and sounds next frame ( to let unequip run )
	task.spawn(function() self:_ProcessEquipAnimation() end)

    -- move model and set motors
    self.ClientModel.Parent = self.Viewmodel.Equipped
    local gripParent = self.Viewmodel:FindFirstChild("RightArm") or self.Viewmodel.RightHand
    gripParent.RightGrip.Part1 = self.ClientModel.GunComponents.WeaponHandle
    
    -- run server equip timer
    task.spawn(function()
        local success = self.ServerEquipEvent.OnClientEvent:Wait()
        if success and self.Variables.equipping then
            self.Variables.equipped = true
            self.Variables.equipping = false
			States.SetStateVariable("PlayerActions", "weaponEquipping", false)
        end
	end)

	-- set movement speed
    self.Controller:HandleHoldMovementPenalty(self.Slot, true)
end

function Weapon:Unequip()
    if not self.Character or self.Humanoid.Health <= 0 then return end

    self:MouseUp(true)
    self:SetIconEquipped(false)

    if self.Options.scope then
        if self.Variables.scoping then
            self:ScopeOut()
        end
        self.Variables.scoping = false
        self.Variables.rescope = false
        self.Variables.scopedWhenShot = false
    end

    self.ClientModel.Parent = game:GetService("ReplicatedStorage").temp
	self.Variables.equipped = false
    self.Variables.firing = false
    self.Variables.reloading = false
	self.Variables.inspecting = false
	States.SetStateVariable("PlayerActions", "weaponEquipped", false)
	States.SetStateVariable("PlayerActions", "weaponEquipping", false)
	States.SetStateVariable("PlayerActions", "reloading", false)
	States.SetStateVariable("PlayerActions", "shooting", false)

    self.Variables.equipping = false

	task.spawn(function()
        self:_StopAllActionAnimations()
        self.CameraObject:StopCurrentRecoilThread()
	end)
end

function Weapon:Remove()
    self.Tool:Destroy()
    self.ClientModel:Destroy()
    for i, v in pairs(self.Connections) do
        v:Disconnect()
    end
    self = nil
end

function Weapon:PrimaryFire()
    if not self.Character or self.Humanoid.Health <= 0 then return end
    if not self.Variables.equipped or self.Variables.reloading or self.Variables.ammo.magazine <= 0 or self.Variables.fireDebounce then return end
    local fireTick = tick()

    -- set var
	States.SetStateVariable("PlayerActions", "shooting", true)

	self.Variables.firing = true
	self.Variables.ammo.magazine -= 1
	self.Variables.currentBullet = (fireTick - self.Variables.lastFireTime >= self.Options.recoilReset and 1 or self.Variables.currentBullet + 1)
	self.Variables.lastFireTime = fireTick
	self.CameraObject.weaponVar.currentBullet = self.Variables.currentBullet

	-- Play Emitters and Sounds
	task.spawn(function()
        self:PlayReplicatedSound("Fire", true)
		SharedWeaponFunctions.ReplicateFireEmitters(self.Tool.ServerModel, self.ClientModel)
	end)

    -- Unscope + rescope if necessary
    if self.Options.scope then
        if self.Variables.scoping then
            self.Variables.rescope = true
            self.Variables.scopedWhenShot = true
            self:ScopeOut()
            task.delay(self.Options.fireRate - 0.03, function()
                if self.Variables.rescope then
                    self:ScopeIn()
                end
            end)
        else
            self.Variables.rescope = false
            self.Variables.scopedWhenShot = false
        end
    end

	-- Create Visual Bullet, Register Camera & Vector Recoil, Register Accuracy & fire to server
	self:RegisterRecoils()

	-- play animations
	self:PlayAnimation("client", "Fire")
    self:PlayAnimation("server", "Fire")
	
	-- handle client fire rate & auto reload
	local nextFire = fireTick + self.Options.fireRate
	task.spawn(function()
		repeat task.wait() until tick() >= nextFire
		self.Variables.firing = false
		States.SetStateVariable("PlayerActions", "shooting", false)
	end)

	-- update hud
	self.Variables.infoFrame.CurrentMagLabel.Text = tostring(self.Variables.ammo.magazine)

	-- send uto reload
	if self.Variables.ammo.magazine <= 0 then
        task.spawn(function()
            repeat task.wait() until not self.Variables.firing
            if self.Variables.equipped then
                self:Reload()
            end
        end)
	end
end

function Weapon:SecondaryFire()
    if not self.Variables.equipped and self.Variables.equipping then return end
    if self.Options.scope then
        if self.Variables.scoping then
            if self.Controller.Keybinds.aimToggle == 1 then
                self:ScopeOut()
            end
            return
        end

        self:ScopeIn()
    end
end

function Weapon:Reload()
    if self.Variables.ammo.total <= 0 or self.Variables.ammo.magazine == self.Options.ammo.magazine then return end
	if self.Variables.firing or self.Variables.reloading or not self.Variables.equipped then return end
    if self.Variables.scoping and self.Options.scope then
        if not self.Variables.rescope then
            self.Variables.rescope = true
            task.delay(self.Options.reloadLength - 0.03, function()
                if self.Variables.rescope then
                    self:ScopeIn()
                end
            end)
        end
        self:ScopeOut()
    end
	
	States.SetStateVariable("PlayerActions", "reloading", true)
	
	task.spawn(function()
        self:PlayAnimation("client", "Reload", true)
		--weaponVar.animations.server.Reload:Play() TODO: make server reload animations
	end)

	self.Variables.reloading = true

	local mag, total = self.RemoteFunction:InvokeServer("Reload")
	self.Variables.ammo.magazine = mag
	self.Variables.ammo.total = total

	-- update hud
	self.Variables.infoFrame.CurrentMagLabel.Text = tostring(mag)
	self.Variables.infoFrame.CurrentTotalAmmoLabel.Text = tostring(total)

	self.Variables.reloading = false
	States.SetStateVariable("PlayerActions", "reloading", false)
end

function Weapon:Inspect()
	if not self.Animations.client.Inspect then return end
	if not self.Variables.equipped or self.Variables.equipping then return end

	-- force start the hold animation if we are still pulling the weapon out
	if not self.Animations.client.Hold.IsPlaying then
        self.Animations.client.Hold:Play()
	end

	-- time skip or play
	if self.Animations.client.Inspect.IsPlaying then
		local skinModel = self.ClientModel:GetAttribute("SkinModel")
		if skinModel then
			if string.match(skinModel, "default") then skinModel = "default" end
			self.Animations.client.Inspect.TimePosition = self.Options.inspectAnimationTimeSkip[string.lower(skinModel)]
		else
			self.Animations.client.Inspect.TimePosition = (self.Options.inspectAnimationTimeSkip and (self.Options.inspectAnimationTimeSkip.default or self.Options.inspectAnimationTimeSkip) or 0)
		end

        return
	end

    self:PlayAnimation("client", "Inspect", true)
end

--

function Weapon:ScopeInit()
    self.Variables.scopeGui = self.Module.Assets.Guis.ScopeGui:Clone()
    self.Variables.scopeGui:WaitForChild("BlackFrame").BackgroundTransparency = 1
    self.Variables.scopeGui.Enabled = false
    self.Variables.scopeGui.Parent = self.Player.PlayerGui

    -- Player Died ScopeOut function
    DiedBind.Event:Once(function()
        if self.Variables.scoping then
            self:ScopeOut()
        end
    end)

    -- Scope Tween Scope
    self.Variables.ScopeTweens = {
        Tweens = {},
        Tables = {ScopeLabelOut = {}},
        Functions = {}
    }

    -- ScopeLabel and Frames Var
    local sgui = self.Variables.scopeGui
    self.Variables.ScopeGuis = {
        Label = sgui.ScopeLabel,
        Frames = {sgui.SideFrameR, sgui.SideFrameL, sgui.SideFrameT, sgui.SideFrameB}
    }

    -- Init ScopeLabel Tweens
    table.insert(self.Variables.ScopeTweens.Tables.ScopeLabelOut, TweenService:Create(sgui.ScopeLabel, TweenInfo.new(self.Options.scopeLength * 0.4), {ImageTransparency = 1}))
    for _, frame in pairs(self.Variables.ScopeGuis.Frames) do
        table.insert(self.Variables.ScopeTweens.Tables.ScopeLabelOut, TweenService:Create(frame, TweenInfo.new(self.Options.scopeLength * 0.4), {BackgroundTransparency = 1}))
    end

    -- Init Scope BlackFrame Tweens
    self.Variables.ScopeTweens.Tweens.BlackFrameInFirst = TweenService:Create(self.Variables.scopeGui.BlackFrame, TweenInfo.new(0.05), {BackgroundTransparency = 0})
    self.Variables.ScopeTweens.Tweens.BlackFrameInLast =  TweenService:Create(self.Variables.scopeGui.BlackFrame, TweenInfo.new(self.Options.scopeLength - 0.05), {BackgroundTransparency = 1})

    --@function Scope Gui In
    self.Variables.ScopeTweens.Functions.In = function()
        self.Variables.ScopeTweens.Tweens.BlackFrameInFirst:Play()
        self.Variables.ScopeTweens.Tweens.BlackFrameInFirst.Completed:Wait()
        Weapon.SetScopeLabelTransparency(self, 0)
        Weapon._SetClientModelTransparency(self, 1)
        UserInputService.MouseDeltaSensitivity = self.Variables.Sensitivity * 0.5
        self.Variables.CrosshairModule:disable()
        self.Variables.ScopeTweens.Tweens.BlackFrameInLast:Play()
    end
    
    --@function Scope Gui Out
    self.Variables.ScopeTweens.Functions.Out = function()
        Weapon._SetClientModelTransparency(self, 0)
        UserInputService.MouseDeltaSensitivity = self.Variables.Sensitivity
        self.Variables.CrosshairModule:enable()
        for _, outTween in pairs(self.Variables.ScopeTweens.Tables.ScopeLabelOut) do
            outTween:Play()
        end
    end

    self.Variables.Sensitivity = UserInputService.MouseDeltaSensitivity

end

function Weapon:ScopeIn()
    self.Variables.scoping = true
    self:PlayReplicatedSound("ScopeIn")

    self:CancelScopeTweens()

    self.Variables.scopeGui.BlackFrame.BackgroundTransparency = 1
    self:SetScopeLabelTransparency(1)
    self.Variables.scopeGui.Enabled = true

    -- fov tweens
    local currfov = PlayerData:Get("options.camera.FOV")
    self.Variables.currFov = currfov
    self.Variables.ScopeTweens.Tweens.FOVIn = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(self.Options.scopeLength), {FieldOfView = currfov * 0.5})
    self.Variables.ScopeTweens.Tweens.FOVOut = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(self.Options.scopeLength * 0.8), {FieldOfView = currfov})
    self.Variables.ScopeTweens.Tweens.FOVIn:Play()

    -- scope gui tweens
    self.Variables.ScopeTweens.Functions.In()

end

function Weapon:ScopeOut()
    self.Variables.scoping = false
    self:PlayReplicatedSound("ScopeOut")

    self:CancelScopeTweens()

    -- Scope
    self.Variables.ScopeTweens.Functions.Out()

    -- FOV
    self.Variables.ScopeTweens.Tweens.FOVOut:Play()
    self.Variables.ScopeTweens.Tweens.FOVOut.Completed:Once(function()
        if not self.Variables.scoping then
            self.Variables.scopeGui.Enabled = false
        end
    end)
end

function Weapon:CancelScopeTweens()
    for _, tab in pairs(self.Variables.ScopeTweens.Tables) do
        for _, tween in pairs(tab) do
            tween:Cancel()
        end
    end

    for _, tween in pairs(self.Variables.ScopeTweens.Tweens) do
        tween:Cancel()
    end
end

function Weapon:SetScopeLabelTransparency(t)
    self.Variables.ScopeGuis.Label.ImageTransparency = t
    for _, frame in pairs(self.Variables.ScopeGuis.Frames) do
        frame.BackgroundTransparency = t
    end
end

--

function Weapon:ConnectActions()
    self.Connections.ActionsDown = UserInputService.InputBegan:Connect(function(input, gp)
        if UIState:hasOpenUI() or gp or (not self.Variables.equipped and not self.Variables.equipping) then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:MouseDown()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:SecondaryFire()
        elseif input.KeyCode == Enum.KeyCode.R then
            self:Reload()
        elseif input.KeyCode == Enum.KeyCode[self.Controller.Keybinds.inspect] then
            self:Inspect()
        end
    end)
    self.Connections.ActionsUp = UserInputService.InputEnded:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:MouseUp()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            self:Mouse2Up()
        end
    end)
    task.wait()
end

function Weapon:DisconnectActions()
    for i, v in pairs(self.Connections) do
        if string.match(i, "Actions") then
            v:Disconnect()
        end
    end
    self.Connections.ActionsDown = nil
    self.Connections.ActionsUp = nil
end

function Weapon:MouseDown(isSecondary: boolean?)
    self.Variables.mousedown = true
    if self.Options.automatic then
        return self:AutomaticMouseDown()
    end

    if self.Variables.fireDebounce then return end

    -- fire input scheduling, it makes semi automatic weapons feel less clunky and more responsive
    if self.Variables.fireScheduleCancelThread then
        self.Variables.fireScheduleCancelThread = nil
        --coroutine.yield(self.Variables.fireScheduleCancelThread)
    end

    -- if a fire is scheduled, no need to do anything.
    if self.Variables.fireScheduled then
        return
    end

    -- if we are already firing and there is no fire scheduled
    if self.Variables.firing then

        -- spawn a thread to shoot automatically after done firing
        self.Variables.fireScheduled = task.spawn(function()
            repeat task.wait() until not self.Variables.firing

            if self.Variables.mousedown then
                if isSecondary then
                    self:SecondaryFire()
                else
                    self:PrimaryFire()
                end
            end

            self.Variables.fireDebounce = false
            self.Variables.fireScheduled = nil
            --coroutine.yield(self.Variables.fireScheduled)
        end)

        return
    end

    if isSecondary then
        self:SecondaryFire()
    else
        self:PrimaryFire()
    end
    self.Variables.fireDebounce = false
end

function Weapon:AutomaticMouseDown()
    if not self.Variables.fireLoop then

        -- register initial fire boolean
        local startWithInit = false

        if tick() >= self.Variables.nextFireTime then
            startWithInit = true
            self.Variables.nextFireTime = tick() + self.Options.fireRate -- set next fire time
            self.Variables.accumulator = 0
        else
            self.Variables.accumulator = self.Variables.nextFireTime - tick()
        end

        -- start fire loop
        self.Variables.fireLoop = RunService.RenderStepped:Connect(function(dt)
            self.Variables.accumulator += dt
            while self.Variables.accumulator >= self.Options.fireRate and self.Variables.mousedown do
                self.Variables.nextFireTime = tick() + self.Options.fireRate
                self.Variables.accumulator -= self.Options.fireRate
                task.spawn(function()
                    self:PrimaryFire()
                end)
                if self.Variables.accumulator >= self.Options.fireRate then task.wait(self.Options.fireRate) end
            end
        end)

        -- initial fire if necessary
        if startWithInit then
            self:PrimaryFire()
        end
    end
end

function Weapon:MouseUp(forceCancel: boolean?)
    self.Variables.mousedown = false
    if not self.Character or self.Humanoid.Health <= 0 then return end

	if self.Variables.fireScheduled then
		if forceCancel then
			--coroutine.yield(self.Variables.fireScheduled)
			self.Variables.fireScheduled = nil
		else
			-- cancel fire scheduled after a full 64 tick of mouse being up
			self.Variables.fireScheduleCancelThread = task.delay(1/64, function()
				if self.Variables.fireScheduled then
					--coroutine.yield(self.Variables.fireScheduled)
					self.Variables.fireScheduled = nil
                    return
				end
                self.Variables.fireScheduleCancelThread = nil
			end)
		end
	end

    if self.Variables.fireLoop then
        self.Variables.fireLoop:Disconnect()
        self.Variables.fireLoop = false
	end

	if not self.Options.automatic then
		self.Variables.fireDebounce = false
		--util_resetSprayOriginPoint()
	end
end

function Weapon:Mouse2Up()
    if self.Options.scope and self.Variables.scoping and self.Controller.Keybinds.aimToggle == 0 then
        self:ScopeOut()
    end
end

--

function Weapon:PlaySound(sound: string, dontDestroyOnRecreate: boolean?, isReplicated: boolean?)

    local weaponName = self.Name
    if not dontDestroyOnRecreate then weaponName = false end

    local _sound = self.Assets.Sounds:FindFirstChild(sound)
    if not _sound then return end

    if _sound:IsA("Folder") then
        for _, v in pairs(_sound:GetChildren()) do
            task.spawn(function()
                if isReplicated then
                    SoundModule.PlayReplicatedClone(v, self.Character.HumanoidRootPart, true)
                else
                    SharedWeaponFunctions.PlaySound(self.Character, weaponName, v)
                end
            end)
        end
        return
    end

    if isReplicated then
        return SoundModule.PlayReplicatedClone(_sound, self.Character.HumanoidRootPart, true)
    else
        return SharedWeaponFunctions.PlaySound(self.Character, weaponName, _sound)
    end
end

function Weapon:PlayReplicatedSound(sound: string, dontDestroyOnRecreate: boolean?)
    return self:PlaySound(sound, dontDestroyOnRecreate, true)
end

--

function Weapon:PlayAnimation(location: "client" | "server", animation: string, highPriority: boolean?)
    local animationTrack: AnimationTrack = self.Animations[location][animation]

	-- connect events
	--[[local wacvm = animationTrack:GetMarkerReachedSignal("VMSpring"):Connect(function(param)
		animationEventFunctions.VMSpring(param)
	end)]]

	local wacs = animationTrack:GetMarkerReachedSignal("PlaySound"):Connect(function(param)
        self:PlaySound(param)
	end)

	local wacrs = animationTrack:GetMarkerReachedSignal("PlayReplicatedSound"):Connect(function(param)
        self:PlayReplicatedSound(param)
	end)

	if highPriority then
        self:_StopAllClientActionAnimations(false, {[animation] = true})
	end

	animationTrack:Play()
	animationTrack.Stopped:Once(function()
		wacs:Disconnect()
		wacrs:Disconnect()
	end)

	return animationTrack
end

function Weapon:_ProcessEquipAnimation()
    self.Controller:_StopAllVMAnimations()
	
	-- disable grenade throwing animation if neccessary
	task.spawn(function()
		local _throwing = States.GetStateVariable("PlayerActions", "grenadeThrowing")
		if _throwing then
			-- find ability folder on character
			if not self.Character:FindFirstChild("AbilityFolder_" .. _throwing) then warn("Could not cancel ability throw anim! Couldnt find ability folder") return end
			self.Character["AbilityFolder_" .. _throwing].Scripts.base_client.communicate:Fire("StopThrowAnimation")
		end
	end)

    task.spawn(function() -- client
        -- play pullout
        local serverPullout = self:PlayAnimation("server", "Pullout")
		local clientPullout = self:PlayAnimation("client", "Pullout")
		clientPullout.Stopped:Wait()
		
        -- dont play hold if not equipped or unequipping
		if self.Variables.forcestop then return end
        if not self.Variables.equipped and not self.Variables.equipping then return end
        self.Animations.client.Hold:Play()
        self.Animations.server.Hold:Play()
    end)
end

function Weapon:_StopAllClientActionAnimations(fadeOut, except) -- except = {animName = true}
	for _, a in pairs(self.Animations.client) do
		if a.Name == "Hold" then continue end
		if except and except[a.Name] then continue end
		a:Stop(fadeOut)
	end
end

function Weapon:_StopAllActionAnimations()
    self.Variables.forcestop = true

	-- stop client first
	for _, a in pairs(self.Animations.client) do
		a:Stop()
	end

	for _, a in pairs(self.Animations.server) do
		a:Stop()
	end

	task.wait(0.06)
	self.Variables.forcestop = false
end

function Weapon:_SetClientModelTransparency(t)
    for i, v in pairs(self.ClientModel:GetDescendants()) do
        if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("Texture") then
            if v.Name == "WeaponHandle" or v:GetAttribute("Ignore") then continue end
            v.Transparency = t
        end
    end
end

--

function Weapon:RegisterRecoils()
    -- Vector Recoil
	task.spawn(function()

		-- grab vector recoil from pattern using the camera object
		local m = self.Player:GetMouse()
        local mray = workspace.CurrentCamera:ScreenPointToRay(m.X, m.Y)
		local currVecRecoil, vecmod = self.CameraObject:getRecoilVector3(self.CameraObject:getSprayPatternKey())
		self.Variables.currentVectorModifier = vecmod

		-- recalculate mray direction to be the height of origin point
		-- the origin point will be reset in conn_mouseUp
		if not self.Variables.originPoint then
			self.Variables.originPoint = {Direction = mray.Direction, Origin = mray.Origin}
		end

		mray = {Direction = mray.Direction, Origin = mray.Origin}
		mray.Direction = Vector3.new(
			mray.Direction.X,
			mray.Direction.Y,
			mray.Direction.Z
		)

		-- get total accuracy and recoil vec direction
		local direction = SharedWeaponFunctions.GetAccuracyAndRecoilDirection(self.Player, mray, currVecRecoil, self.Options, self.Variables)

		-- check to see if we're wallbanging
		local wallDmgMult, hitchar, result
		local normParams = SharedWeaponFunctions.getFireCastParams(self.Player, workspace.CurrentCamera)
		wallDmgMult, result, hitchar = self:_ShootWallRayRecurse(mray.Origin, direction * 250, normParams, nil, 1)

		if result then

			--print(result)

			-- register client shot for bullet/blood/sound effects
			SharedWeaponFunctions.RegisterShot(self.Player, self.Options, result, mray.Origin, nil, nil, hitchar, wallDmgMult or 1, wallDmgMult and true or false, self.Tool, self.ClientModel)

			-- pass ray information to server for verification and damage
			self.RemoteEvent:FireServer("Fire", self.Variables.currentBullet, false, SharedWeaponFunctions.createRayInformation(mray, result), workspace:GetServerTimeNow(), wallDmgMult)
			--weaponRemoteFunction:InvokeServer("Fire", weaponVar.currentBullet, false, sharedWeaponFunctions.createRayInformation(mray, result), workspace:GetServerTimeNow(), wallDmgMult)
			return true
		end

		-- nothing hit
		-- this shouldn't happen if the map is set
		-- up with bullet colliders surrounding the map
		return false
	end)

	-- fire camera recoil once accuracy has been calculated
	-- to avoid the bullet going where the camera recoil is
	self.CameraObject:FireRecoil(self.Variables.currentBullet)
end

--@return damageMultiplier (total damage reduction added up from recursion)
function Weapon:_ShootWallRayRecurse(origin, direction, params, hitPart, damageMultiplier, filter)

	if not filter then filter = params.FilterDescendantsInstances end

	local _p = RaycastParams.new()
	_p.CollisionGroup = "Bullets"
	_p.FilterDescendantsInstances = filter
	_p.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, direction, _p)
	if not result then warn("No wallbang result but player result") return false end

	local hitchar = result.Instance:FindFirstAncestorWhichIsA("Model")
	if hitchar and hitchar:FindFirstChild("Humanoid") then
		return damageMultiplier, result, hitchar
	end

	local bangableMaterial = result.Instance:GetAttribute("Bangable") or hitchar:GetAttribute("Bangable")
	if not bangableMaterial then return false, result end

	for _, v in pairs(filter) do
		if result.Instance == v then warn("Saved you from a life of hell my friend") return false end
	end

	-- create bullethole at wall
    SharedWeaponFunctions.CreateBulletHole(result)
	--SharedWeaponFunctions.RegisterShot(self.Player, self.Options, result, origin, nil, nil, nil, nil, true, self.Tool, self.ClientModel)

	table.insert(filter, result.Instance)
	return self:_ShootWallRayRecurse(origin, direction, _p, result.Instance, (damageMultiplier + weaponWallbangInformation[bangableMaterial])/2, filter)
end

--

function Weapon:SetIconEquipped(equipped: boolean)
    if equipped then
        self.Variables.weaponIconEquipped.ImageColor3 = self.Variables.weaponIconEquipped.Parent:GetAttribute("EquippedColor")
    else
        self.Variables.weaponIconEquipped.ImageColor3 = self.Variables.weaponIconEquipped.Parent:GetAttribute("UnequippedColor")
    end
end

--@summary Set the user's weapon HUD to display guns or knife
function Weapon:SetInfoFrame(weapon: "gun" | "knife")
    if weapon == "gun" then
        self.Variables.infoFrame.KnifeNameLabel.Visible = false
        self.Variables.infoFrame.GunNameLabel.Visible = true
        self.Variables.infoFrame.CurrentMagLabel.Visible = true
        self.Variables.infoFrame.CurrentTotalAmmoLabel.Visible = true
        self.Variables.infoFrame["/"].Visible = true
        self.Variables.infoFrame.CurrentMagLabel.Text = tostring(self.Variables.ammo.magazine)
        self.Variables.infoFrame.CurrentTotalAmmoLabel.Text = tostring(self.Variables.ammo.total)
        self.Variables.infoFrame.GunNameLabel.Text = Strings.firstToUpper(self.Name)
    elseif weapon == "knife" then
        self.Variables.infoFrame.KnifeNameLabel.Visible = true
        self.Variables.infoFrame.GunNameLabel.Visible = false
        self.Variables.infoFrame.CurrentMagLabel.Visible = false
        self.Variables.infoFrame.CurrentTotalAmmoLabel.Visible = false
        self.Variables.infoFrame["/"].Visible = false
    end
end

return Weapon
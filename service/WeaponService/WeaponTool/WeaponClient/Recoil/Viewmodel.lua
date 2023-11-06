local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
local VMSprings = require(Framework.Module.lib.c_vmsprings)
local Math = require(Framework.Module.lib.fc_math)

local function clone(tab)
    local new = {}
    for i, v in pairs(tab) do
        if type(v) == "table" then
            new[i] = clone(v)
        else
            new[i] = v
        end
    end
    return new
end

local Cfg
Cfg = {
    _def = {
        pos = {
			mass = 5,		-- 5
			force = 50,		-- 50
			damping = 4,	-- 4
			speed = 3,		-- 4
			multiplier = 0.2, -- 1
			min = Vector3.new(0, -1.1, -.5),
			max = Vector3.new(0, 1.1, 0)
		},
        rotUp = {
            mass = 5,		-- 5
            force = 50,		-- 50
            damping = 4,	-- 4
            speed = 1,		-- 4
            multiplier = 1, -- 1
            min = -1.1,
            max = 1.1
        },
        rotSide = {
            mass = 5,		-- 5
            force = 50,		-- 50
            damping = 3,	-- 4
            speed = 0.8,		-- 4
            multiplier = 2.2, -- 1
            min = -5,
            max = 5
        }
    },

    get = function(Weapon)
        return Cfg.resolve(Weapon.Options.fireSpring or {})
    end,

    resolve = function(sendTab, defaultTab)
        defaultTab = defaultTab or Cfg._def
        for i, v in pairs(defaultTab) do
            if not sendTab[i] then
                if type(v) == "table" then
                    sendTab[i] = Cfg.resolve({}, defaultTab[i])
                else
                    sendTab[i] = v
                end
            end
        end
        return sendTab
    end
}

local Spring
Spring = {
    create = function(vmModule, name, options, updateFunc, climbFunc)
        options = Spring.getOptions(options)
        local spring = VMSprings:new(options.mass, options.force, options.damping, options.speed)
        local customSpring = vmModule:addCustomSpring(name, true, spring, false, false, function(vm, dt)
            updateFunc(spring, vm, dt)
        end)
        customSpring.Properties = options
        customSpring.Climb = function(recoil)
            climbFunc(recoil, options)
        end
        return customSpring
    end,
    getOptions = function(options)
        local _t = {mass = 5, force = 50, damping = 4, speed = 4}
        if options then
            for i, v in pairs(options) do
                _t[i] = v
            end
        end
        return _t
    end,
    updatePos = function(spring, vm, dt)
        local updated = spring:update(dt)
        vm.vmhrp.CFrame *= CFrame.new(updated.X, updated.Y, updated.Z)
    end,
    updateRot = function(spring, vm, dt)
        local updated = spring:update(dt)
        vm.vmhrp.CFrame = vm.vmhrp.CFrame:ToWorldSpace(CFrame.Angles(math.rad(updated.X), math.rad(updated.Y), math.rad(updated.Z)))
    end,
    climbPos = function(self, recoil, properties)
        if recoil.X ~= self._lastPos then
            local mult = properties.multiplier * self._camModifier
            local y = math.clamp(self._totalPos.Y + (recoil.X * mult), properties.min.Y, properties.max.Y)
            local z = math.clamp(self._totalPos.Z + (recoil.X * mult), properties.min.Z, properties.max.Z)
            self._totalPos = Vector3.new(self._totalPos.X, y, z)
        end
        self._lastPos = recoil.X
    end,
    climbRotUp = function(self, recoil, properties)
        if recoil.X ~= self._lastRotUp then
            local mult = properties.multiplier * self._camModifier
            local _climb = self._totalRotUp + (Vector3.new(recoil.X, 0, 0) * mult)
            self._totalRotUp = Math.vector3Clamp(_climb, properties.min, properties.max)
        end
        self._lastRotUp = recoil.X
    end,
    climbRotSide = function(self, recoil, properties)
        if recoil.Y ~= self._totalRotSide then
            local mult = properties.multiplier * self._camModifier
            local _climb = self._totalRotSide + (Vector3.new(0, recoil.Y, 0) * mult)
            self._totalRotSide = Math.vector3Clamp(_climb, properties.min, properties.max)
        end
        self._lastRotSide = recoil.Y
    end
}

local Debug = {
    GetAttributes = function(self) -- Attribute Example: "RotSide_Speed" = 5
        local char = self.Character
        for _, vt in pairs({"Speed", "Mass", "Damping", "Force"}) do
            local att = char:GetAttribute(vt)
            if att then
                self.Springs.FireRotSideSpring.Spring[vt] = att
            end
        end
    end
}

local Viewmodel = {}

function Viewmodel:init()
    self.Springs = {}
    self.Cfg = Cfg.get(self)
    Viewmodel.ResetVar(self)

    -- Pos Spring (Up Axis Transform)
    local firePosSpring = Spring.create(self.ViewmodelModule, self.Name .. "_FirePosSpring", self.Cfg.pos, Spring.updatePos,
        function(recoil, properties)
            Spring.climbPos(self, recoil, properties)
        end)
    self.CameraObject.FirePosSpring = firePosSpring
    self.Springs.FirePosSpring = firePosSpring
    
    -- Rot Up Spring (Up Axis Rotation)
    local fireRotUpSpring = Spring.create(self.ViewmodelModule, self.Name .. "_FireRotUpSpring", self.Cfg.rotUp, Spring.updateRot,
        function(recoil, properties)
            Spring.climbRotUp(self, recoil, properties)
        end)
    self.CameraObject.FireRotUpSpring = fireRotUpSpring
    self.Springs.FireRotUpSpring = fireRotUpSpring

    -- Rot Side Spring (Side Axis Rotation)
    local fireRotSideSpring = Spring.create(self.ViewmodelModule, self.Name .. "_FireRotSideSpring", self.Cfg.rotSide, Spring.updateRot,
        function(recoil, properties)
            Spring.climbRotSide(self, recoil, properties)
        end)
    self.CameraObject.FireRotSideSpring = fireRotSideSpring
    self.Springs.FireRotSideSpring = fireRotSideSpring
end

function Viewmodel:ResetVar()
    self._lastRotUp = 0
    self._lastRotSide = 0
    self._lastPos = 0
    self._totalPos = Vector3.zero
    self._totalRotUp = Vector3.zero
    self._totalRotSide = Vector3.zero
end

function Viewmodel:Fire(currentBullet, recoilValues)
    if currentBullet == 1 then
        Viewmodel.ResetVar(self)
    end

    recoilValues *= self.GLOBAL_VIEWMODEL_MULT

    -- | Update Spring Variables |
    self.Springs.FirePosSpring.Climb(recoilValues)
    self.Springs.FireRotSideSpring.Climb(recoilValues)
    self.Springs.FireRotUpSpring.Climb(recoilValues)

    -- | Shove Springs |
    self.Springs.FirePosSpring.Spring:shove(self._totalPos)
    self.Springs.FireRotSideSpring.Spring:shove(self._totalRotSide)
    self.Springs.FireRotUpSpring.Spring:shove(self._totalRotUp)
end

return Viewmodel
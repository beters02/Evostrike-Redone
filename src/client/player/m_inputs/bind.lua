--[[ Binding Functions for m_inputs ]]

local bind = {}
local types = require(script.Parent.types)
local died = game:GetService("ReplicatedStorage"):WaitForChild("main"):WaitForChild("sharedMainRemotes"):WaitForChild("deathBE")

--[[ Bind an action to a key ]]

function bind:Bind(key: string, actionID: string, properties: types.KeyActionProperties, packedArguments: table, action: types.TFunction, keyUpAction: types.TFunction?): types.KeyAction

    if not self._boundKeyActions[key] then
         self._boundKeyActions[key] = {_keyProperties = {IsMouseKey = string.match(key, "Mouse") and true or false}}
    end

    if self._boundKeyActions[key][actionID] then
        self._boundKeyActions[key][actionID].Unbind()
        --warn("Automatically unbound previous action from " .. tostring(actionID))
    end

    local _ka: types.KeyAction = {
        Function = action,
        KeyUpFunction = keyUpAction,
        Args = packedArguments,
        Var = {debounce = tick(), enabled = true, conn = {}},
        Properties = properties,

        -- quick acccess unbind
        Unbind = function()
            return self:Unbind(key, actionID)
        end
    }

    -- set debounce to boolean for non repeating
    if not _ka.Properties.Repeats then _ka.Var.debounce = false end

    -- overwrite prop if necessary
    if _ka.Properties.Var and type(_ka.Properties.Var) == "table" then
        for i, v in pairs(_ka.Properties.Var) do
            _ka.Var[i] = v
        end
    end

    -- connect death event if necessary
    if _ka.Properties.DestroyOnDead then
        _ka.Var.conn.died = died.Event:Once(function()
            _ka.Unbind()
        end)
    end

    self._boundKeyActions[key][actionID] = _ka

    return _ka
end

--[[ Unbind a key's action ]]

function bind:Unbind(key: string, actionID: string)
    
    if not self._boundKeyActions[key] then
        error("Cannot unbind key - key is not bound!")
    end

    if not self._boundKeyActions[key][actionID] then
        error("Cannot unbind key with this actionID!")
    end

    if self._boundKeyActions[key][actionID].Var.conn then
        for i, v in pairs(self._boundKeyActions[key][actionID].Var.conn) do
            v:Disconnect()
        end
    end

   self._boundKeyActions[key][actionID] = nil
end

--[[ Check if a key is bound ]]

function bind:IsKeyBound(key: string): table -- table<KeyAction>
    return self._boundKeyActions[key] or false
end

--
--

function bind._init(self)
    -- store bound key actions
    self._boundKeyActions = {}
end

return bind
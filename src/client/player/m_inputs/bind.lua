--[[ Binding Functions for m_inputs ]]

local bind = {}

export type TFunction = (...any) -> (...any)

export type KeyActionProperties = {
    Repeats: boolean,
    RepeatDelay: number?,
    IgnoreOnDead: boolean,
    IgnoreWhen: table?, -- table<() -> (boolean)>, will ignore when any of these functions return true
    Var: table? -- overwrite var
}

export type KeyAction = {
    Function: TFunction,
    KeyUpFunction: TFunction?,
    Args: table,
    Var: table,
    Properties: KeyActionProperties,
    Unbind: TFunction
}

--[[ Bind an action to a key ]]

function bind:Bind(key: string, actionID: string, properties: KeyActionProperties, packedArguments: table, action: TFunction, keyUpAction: TFunction?): KeyAction

    if not self._boundKeyActions[key] then
         self._boundKeyActions[key] = {_keyProperties = {IsMouseKey = string.match(key, "Mouse") and true or false}}
    end

    if self._boundKeyActions[key][actionID] then
        self._boundKeyActions[key][actionID].Unbind()
        --warn("Automatically unbound previous action from " .. tostring(actionID))
    end

    local _ka: KeyAction = {
        Function = action,
        KeyUpFunction = keyUpAction,
        Args = packedArguments,
        Var = {debounce = tick()},
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
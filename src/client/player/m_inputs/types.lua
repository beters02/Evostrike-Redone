export type TFunction = (...any) -> (...any)

export type KeyActionProperties = {
    Repeats: boolean,
    RepeatDelay: number?,
    DestroyOnDead: boolean,
    IgnoreOnDead: boolean|false,
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

return nil
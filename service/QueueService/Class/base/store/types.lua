-- Arguments table which was created by table.pack
export type Arguments = table

export type DataProcessStatus = string

-- Process Functions must return SOMETHING, if erroring it will return false.
export type DataProcess = {
    Function: (...any) -> (...any),
    Args: Arguments,
    Retries: number,
    Status: DataProcessStatus,
    Var: {},
    Result: BindableEvent,
    Cleanup: () -> (),
    Connections: table
}

return nil
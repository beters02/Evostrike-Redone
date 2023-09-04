-- Queue PlayerData is what is stored in the DataStore. (key = Name, value = Slot)
export type QueuePlayerData = {
    Name: string,
    Slot: number,
    Objects: table -- Sometimes we will want to store Events and such in here
}

-- QueueService PlayerData is information about the player that is stored locally.
-- If a player is currently being processed in a queue (adding, removing, teleporting),
-- then we will store that data here and send the data to any servers asking for it.
-- We do this so we don't accidentally process the same player multiple times.
export type QueueServicePlayerData = {
    Name: string,
    Processing: boolean
}

-- Arguments table which was created by table.pack
export type Arguments = table

-- Status of a DataProcess
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
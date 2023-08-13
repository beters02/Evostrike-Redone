export type Module = {
    Access: string, -- Client, Server, Shared
    Client: LocalScript?,
    Server: Script?,
    Location: ModuleScript
}

export type PlayerModule = {
    Access: string,
    Client: LocalScript,
    Server: Script,
    Location: ModuleScript
}

export type ServiceModule = PlayerModule

export type FunctionContainer = {
    Access: string,
    Location: ModuleScript
}

export type Class = {
    Access: string,
    Location: ModuleScript
}

return nil
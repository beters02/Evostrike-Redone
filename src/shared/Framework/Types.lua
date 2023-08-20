--[[
    [Module] = A ModuleScript that contains more than 1 function and that involves connections.
    - A [Module] will **sometimes** have a [ModuleServerScript] __and/or__ a [ModuleClientScript]
    - A [Module] will **never** be responsible for connections. This is what the [ModuleServerScript] and [ModuleClientScript] are for.
]]

export type Module = {
    Access: string, -- Client, Server, Shared
    Client: LocalScript?,
    Server: Script?,
    Location: ModuleScript
}

--[[
    [PlayerModule] = A [Module] that contains Player-Related functions (Weapon, Ability)
    - A [PlayerModule] will **always** have a [PlayerModuleClientScript] __and__ a [PlayerModuleServerScript]
]]

export type PlayerModule = {
    Access: string,
    Client: LocalScript,
    Server: Script,
    Location: ModuleScript
}

--[[
    [ServiceModule] = A Special [Module] that is an object which creates a service.
    - A [ServiceModule] will **always** a [PlayerModuleClientScript] __and__ a [PlayerModuleServerScript]
    - A [ServiceModule] will **always** be responsible for connections. The Client and Server script are only responsible for requiring the module. (WIP, TBC)
]]

export type ServiceModule = PlayerModule

--[[
    [Class] = A ModuleScript that returns a class.
    - A [Class] will **never** have a [ModuleServerScript] __and/or__ a [ModuleServerScript]
    - A [Class] will **always** be responsible for connections.
    - A [Class] will **always** stay in the Game Scope that it was created in. (Client -> Client, Server -> Server, Shared -> Shared)
]]

export type Class = {
    Access: string,
    Location: ModuleScript
}

--[[
    [Function] = A ModuleScript that contains only 1 function.
    - A [Function] will **never** have a [ModuleServerScript] __and/or__ a [ModuleServerScript]
    - A [Function] will **always** be responsible for any connections.
    - A [Function] will **always** be created in the Game Scope that it was intended to be created in. (Client -> Client, Server -> Server, Shared -> Shared)
]]

export type Function = (...any) -> (...any)

--[[
    [FunctionContainer] = A ModuleScript that contains more than 1 function and that does not involve any connections.
    - A [FunctionContainer] will **never** contain mutable variables.
]]

export type FunctionContainer = {
    Access: string,
    Location: ModuleScript
}

--[[
    [PlayerFunction] = Player-Related Module Scripts that contain only 1 function
    [GameObject] = Any object that can be found within the game framework. (Modules, Folders)
    [ScriptGameObject] = A [GameObject] that is a script and not a ModuleScript.
]]

return nil
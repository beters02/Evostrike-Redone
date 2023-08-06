-- LerpSoh

type Dictionary = { [string]: any }
type DefineDictionary<Type> = { [string]: Type }

export type Table = { [any]: any }
export type DefineTable<Value> = { [string]: Value }

export type Array = { [number]: any }
export type DefineArray<Type> = { [number]: Type }

export type Function = (...any) -> ...any
export type DefineFunction<Return> = (...any) -> Return

export type Shared = {
	NewSharedClass: (self: any, ClassName: string, Recursive: boolean | any, ...any) -> Table,
	GetSharedClass: (self: any, Name: string, Recursive: boolean) -> Table,

	GetSharedModule: (self: any, Name: string, Recursive: boolean) -> Table,

	GetEngine: (self: any, Name: string, Recursive: boolean) -> Table,
	GetLibrary: (self: any, Name: string, Recursive: boolean) -> Table,

	GetService: (self: any, Name: string, Recursive: boolean) -> Table,

	GetPackage: (self: any, Name: string, Recursive: boolean) -> Instance | Table,

	GetSharedAsset: (self: any, Name: string, Recursive: boolean) -> Instance | Table,
	GetAllSharedAssets: (self: any) -> DefineArray<Instance>,
} & ExternalShared

export type Client = {
	Setup: (self: any) -> never,

	Heartbeat: (self: any, Time: number) -> never,
	Stepped: (self: any, Time: number) -> never,
	RenderStepped: (self: any, Time: number) -> never,

	Start: (self: any) -> never,

	NewClass: (self: any, ClassName: string, Recursive: boolean | any, ...any) -> Table,
	GetClass: (self: any, Name: string, Recursive: boolean) -> Table,

	GetModule: (self: any, Name: string, Recursive: boolean) -> Table,

	GetGui: (self: any, Name: string, Recursive: boolean) -> GuiBase2d,
	GetBackpack: (self: any, Name: string, Recursive: boolean) -> BackpackItem,

	Warn: (self: any, any) -> never,

	Classes: Folder,
	Modules: Folder,
	Scripts: Folder,

	Player: Player,
	Gui: PlayerGui,
	Backpack: Backpack,
	Character: Model,
	Assets: Folder,
} & Shared & ExternalClient

type ExternalShared = {}
type ExternalClient = {}

return nil

--local Types = {}

--export type Function = (...any) -> ...any

-- typeof(metatable) gives the linter information about what methods are in your class.

-- unioning typeof({index = nil :: never}) tells the linter to separate methods and properties.

-- We also set __index in the type definition to a "never" type so that it is clear to the programmer
-- that it should not be used.

-- A combination of all of this only autofills class functions, object functions, and public properties

--[[function Types.check(Class)
    local ClassInstance = setmetatable({__index = nil :: never}, Class)
	return nil :: typeof(ClassInstance) & typeof({__index = nil :: never})
end]]

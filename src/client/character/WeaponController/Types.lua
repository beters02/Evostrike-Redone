export type Function<I, O> = (I) -> (O)
export type WeaponActionFunction = Function<...any, ...any>

export type WeaponSlot = "primary" | "secondary" | "ternary"

export type WeaponActionFunctions = {
    firedown: WeaponActionFunction,
	secondaryfiredown: WeaponActionFunction,
	fireup: WeaponActionFunction,
	startinspect: WeaponActionFunction,
	stopinspect: WeaponActionFunction,
    reload: WeaponActionFunction,
    remoteEvent: RemoteEvent
}

export type Weapon = {
    Name: string,
    Slot: WeaponSlot,
    Tool: Tool,
    ClientModel: Model,
    Options: table,
    Connections: table,
    ActionFunctions: WeaponActionFunctions,

    Remove: () -> (),
    ConnectActions: () -> (),
    DisconnectActions: () -> (),

    IsKnife: boolean
}

export type WeaponController = {
    Owner: Player,
    Inventory: {equipped: Weapon | false, last_equipped: Weapon | false, primary: Weapon | false, secondary: Weapon | false, ternary: Weapon | false},
    Connections: table,
    Processing: boolean,
    CanEquip: boolean,
    Keybinds: {},

    Connect: () -> (),
    Disconnect: () -> (),
    Remove: () -> (),

    AddWeapon: (WeaponController, string) -> (boolean),
    RemoveWeapon: (WeaponController, string | WeaponSlot) -> (boolean),
    ClearInventory: (WeaponController) -> (),
    GetEquippedWeapon: (WeaponController) -> (Weapon),

    EquipWeapon: (WeaponController) -> (),
    UnequipWeapon: (WeaponController) -> ()
}

return nil
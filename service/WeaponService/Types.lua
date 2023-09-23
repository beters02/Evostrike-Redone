local LocalizationService = game:GetService("LocalizationService")
export type Function = (...any) -> (...any)
export type AFunction<I, I1, O> = (I, I1) -> (O)
export type WeaponSlot = "primary" | "secondary" | "ternary"

export type ControllerFunction = (WeaponController) -> ()
export type WeaponFunction = (Weapon) -> ()

export type Weapon = {
    Player: Player,
    Character: Model,
    Humanoid: Humanoid,
    Viewmodel: Model,
    Name: string,
    Slot: WeaponSlot,
    Tool: Tool,
    Options: table,
    ClientModel: Model,
    Controller: WeaponController,
   
    Module: ModuleScript,
    Assets: Folder,
    Connections: table,
    Variables: table,
    Animations: table,

    Remove: WeaponFunction,

    ConnectActions: WeaponFunction,
    DisconnectActions: WeaponFunction,

    PrimaryFire: WeaponFunction,
    SecondaryFire: WeaponFunction,
    Equip: WeaponFunction,
    Unequip: WeaponFunction,
    Reload: WeaponFunction,
    Inspect: WeaponFunction,

    PlayAnimation: (self: Weapon, location: "client" | "server", animation: string) -> (),
    PlaySound: (self: Weapon, sound: string) -> (),
    PlayReplicatedSound: (self: Weapon, sound: string) -> (),
    
}

export type WeaponController = {
    Owner: Player,
    Humanoid: Humanoid,
    Inventory: {equipped: Weapon | false, last_equipped: Weapon | false, primary: Weapon | false, secondary: Weapon | false, ternary: Weapon | false},
    Connections: table,
    Processing: boolean,
    CanEquip: boolean,
    Keybinds: {},

    Connect: () -> (),
    Disconnect: () -> (),
    Remove: () -> (),

    AddWeapon: (self: WeaponController, weapon: string) -> (Weapon | false),
    RemoveWeapon: (self: WeaponController, weapon: string | WeaponSlot) -> (Weapon | false),
    ClearInventory: (WeaponController) -> (),
    GetEquippedWeapon: (WeaponController) -> (Weapon),
    SetIconEquipped: Function,

    EquipWeapon: (self: WeaponController, WeaponSlot: WeaponSlot) -> (),
    UnequipWeapon: (self: WeaponController, WeaponSlot: WeaponSlot) -> ()
}

return nil
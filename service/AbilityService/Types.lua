export type Function = (...any) -> (...any)
export type AFunction<I, I1, O> = (I, I1) -> (O)
export type ControllerFunction = (self: AbilityController, ...any) -> (...any)
export type AbilityFunction = (self: Ability, ...any) -> (...any)

export type AbilitySlot = "primary" | "secondary"

export type Ability = {
    Name: string,
    Slot: string,
    Variables: table,
    Animations: table,
    Module: ModuleScript,

    Player: Player,
    Character: Model,
    Humanoid: Humanoid,
    Viewmodel: Model,
    Frame: Frame,
    Icon: ImageLabel?,
    Controller: AbilityController,

    Use: AbilityFunction,
    UseCore: AbilityFunction
}

export type AbilityController = {
    Name: string,
    Slot: string,
    Key: string,

    Owner: Player,
    Humanoid: Humanoid,

    Connect: ControllerFunction,
    Disconnect: ControllerFunction,

    AddAbility: ControllerFunction,
    RemoveAbility: ControllerFunction
}

return nil
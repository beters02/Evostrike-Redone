export type Console = {
    UI: ScreenGui,
    MainFrame: Frame,

    Open: () -> (),
    Close: () -> (),
    Toggle: () -> (),

    IsOpen: () -> boolean
}

export type ReturnMessageType = "message" | "warn" | "error"

export type Command = {
    Name: string,
    Alias: table?,
    Function: (...any) -> (...any)
}

return nil
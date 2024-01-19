local Movement = {
    properties = {
        id = "Movement",
        replicated = false,
        clientReadOnly = false,
        owner = "Client"
    },
    defaultVar = {
        grounded = false,
        landing = false,
        crouching = false
    }
}

return Movement
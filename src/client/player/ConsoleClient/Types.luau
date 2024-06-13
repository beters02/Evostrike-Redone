local Types = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"):WaitForChild("Types"))

-----

export type ConsoleCfg = Types.ConsoleCfg

export type CConsole = Types.CConsole

export type AutoFillModule = Types.AutoFillModule

export type SCommand = Types.SCommand

local secretCommandErrorMessages = {
    penis = "lmao you thought thatd be a command?",
    faggot = "<3 !THATS ME BABY! <3",
}

function secretCommandErrorMessages._supplyErrorMessageFromWordsArr(words, defaultMsg)
    local errorMsg = defaultMsg
    for _, v in pairs(words) do
        local n = secretCommandErrorMessages[string.lower(v)]
        if n then
            errorMsg = n
            break
        end
    end
    return errorMsg
end

return {secreterr = secretCommandErrorMessages}
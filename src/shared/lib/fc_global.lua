local global = {}

function global.wassert(bool: any, msg: string)
    if bool then
        return bool
    end
    warn(msg)
    return false
end

return global
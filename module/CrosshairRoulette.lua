    -- io am really drunk =D

    local cr = {}

    function cr:Generate()
        local gap = math.random(0, 50)
        if gap > 0 then
            gap = gap * (math.random(1,2) == 1 and -1 or 1)
        end
        local size = math.random(0, 50)
        local thickness = math.random(0, 50)
        print(gap, size, thickness)
    end

    return cr
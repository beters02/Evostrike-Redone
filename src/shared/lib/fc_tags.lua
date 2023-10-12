local CollectionService = game:GetService("CollectionService")

local Tags = {}

function Tags.DestroyTagged(tag)
    for _, v in ipairs(CollectionService:GetTagged(tag)) do
        v:Destroy()
    end
end

return Tags
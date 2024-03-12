local CollectionService = game:GetService("CollectionService")

for _, ambientPart in pairs(CollectionService:GetTagged("Ambience")) do
    for _, sound in pairs(ambientPart:GetChildren()) do
        if not sound:IsA("Sound") then
            continue
        end
        sound.Looped = true
        sound:Play()
    end
end
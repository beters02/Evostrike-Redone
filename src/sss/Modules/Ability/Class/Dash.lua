local Dash = {

    -- movement settings
    strength = 50,
    upstrength = 25,

    -- gemeral settings
    cooldownLength = 3,
    uses = 100,

    -- data settings
    abilityName = "Dash",
    inventorySlot = "primary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
}

function Dash:Use()
    self.uses -= 1
    self.startCF = self.player.Character.PrimaryPart.CFrame

    task.spawn(function()
        local canUse = self:ServerUseVarCheck()
        if not canUse then self:UseFailed() end
    end)

    self.player.Character.MovementScript.Events.Dash:Fire(Dash.strength, Dash.upstrength)
end

function Dash:UseFailed()
    self.player.Character:SetPrimaryPartCFrame(self.startCF)
end

return Dash
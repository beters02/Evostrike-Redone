local Dash = {

    -- movement settings
    strength = 50,
    upstrength = 20,

    -- gemeral settings
    cooldownLength = 3,
    uses = 2,

    -- data settings
    abilityName = "Dash",
    inventorySlot = "primary",

    player = game:GetService("Players").LocalPlayer or nil, -- set to nil incase required from server,

    remoteFunction = nil, -- to be added in AbilityClient upon init
}

function Dash:Use()
    self.uses -= 1
    self.startCF = self.player.Character.PrimaryPart.CFrame

    task.spawn(function() -- if uses on server is mismatched, player will be teleported back to startCF
        local newUses = self.remoteFunction:InvokeServer("SubUses")
        if newUses < 0 then
            self.player.Character:SetPrimaryPartCFrame(self.startCF)
            return warn("DASH USE MISMATCH")
        end
        self.uses = newUses
        print(self.uses)
    end)

    self.player.Character.MovementScript.Events.Dash:Fire(Dash.strength, Dash.upstrength)
end

return Dash
--[[local AssetService = game:GetService("AssetService")
local part = game:GetService("ReplicatedStorage"):WaitForChild("Assets").Models.Coin_low.Coin_low:Clone()
part = AssetService:CreateEditableMeshFromPartAsync(part)
part.VertexColor = Color3.new(0.435294, 0.435294, 0.435294)
part.Anchored = true
part.CFrame = workspace:WaitForChild("Part").CFrame
workspace.Part:Destroy()]]
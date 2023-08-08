local Players = game:GetService("Players")

local Remotes = {}

function Remotes.InvokeAllClients(remote, ...)
	for i, v in pairs(Players:GetPlayers()) do
		remote:InvokeClient(v, ...)
	end
end

function Remotes.InvokeAllClientsExcept(remote, except, ...)
	if typeof(except) ~= "table" then
		except = {except}
	end

	for i, v in pairs(Players:GetPlayers()) do
		if table.find(except, v) then continue end
		remote:InvokeClient(v, ...)
	end
end

function Remotes.FireAllClients(remote, ...)
	for i, v in pairs(Players:GetPlayers()) do
		remote:FireClient(v, ...)
	end
end

function Remotes.FireAllClientsExcept(remote, except, ...)
	if typeof(except) ~= "table" then
		except = {except}
	end

	for i, v in pairs(Players:GetPlayers()) do
		if table.find(except, v) then continue end
		remote:FireClient(v, ...)
	end
end

--TODO: Test Function

return Remotes
--------------------------------------------------
-- TOGGLE
--------------------------------------------------
if getgenv().NO_RAGDOLL then
	getgenv().NO_RAGDOLL = false

	if getgenv().NO_RAGDOLL_CONNS then
		for _,c in pairs(getgenv().NO_RAGDOLL_CONNS) do
			pcall(function()
				c:Disconnect()
			end)
		end
	end

	getgenv().NO_RAGDOLL_CONNS = {}
	return
end

getgenv().NO_RAGDOLL = true
getgenv().NO_RAGDOLL_CONNS = {}
--------------------------------------------------

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local live = workspace:WaitForChild("Live")

local function setup(model)

	if not getgenv().NO_RAGDOLL then return end

	for _,v in ipairs(model:GetDescendants()) do
		if v.Name == "Ragdoll" or v.Name == "RagdollSim" then
			v:Destroy()
		end
	end

	table.insert(getgenv().NO_RAGDOLL_CONNS,
		model.DescendantAdded:Connect(function(v)

			if not getgenv().NO_RAGDOLL then return end

			if v.Name == "Ragdoll" or v.Name == "RagdollSim" then
				task.defer(function()
					if v and v.Parent then
						v:Destroy()
					end
				end)
			end

		end)
	)

end

local m = live:FindFirstChild(lp.Name)
if m then
	setup(m)
end

table.insert(getgenv().NO_RAGDOLL_CONNS,
	live.ChildAdded:Connect(function(v)

		if not getgenv().NO_RAGDOLL then return end

		if v.Name == lp.Name then
			setup(v)
		end

	end)
)

-- LocalScript: put in StarterPlayer > StarterPlayerScripts
-- Keeps PlayerGui.Home.hud.BackpackUI.Toolbar AND everything directly inside it visible.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PATH = { "Home", "hud", "BackpackUI", "Toolbar" }

local hooked = {}

local function force(inst)
	if inst:IsA("ScreenGui") then
		if not inst.Enabled then inst.Enabled = true end
	elseif inst:IsA("GuiObject") then
		if not inst.Visible then inst.Visible = true end
	end
end

-- turns it on now, and again the instant something turns it off
local function hook(inst)
	if hooked[inst] then return end
	local isScreenGui = inst:IsA("ScreenGui")
	if not (isScreenGui or inst:IsA("GuiObject")) then return end

	hooked[inst] = true
	force(inst)

	inst:GetPropertyChangedSignal(isScreenGui and "Enabled" or "Visible"):Connect(function()
		force(inst)
	end)
	inst.Destroying:Connect(function()
		hooked[inst] = nil
	end)
end

-- walks Home > hud > BackpackUI > Toolbar, then hooks every slot inside it
local function enforce()
	local current = playerGui
	for _, name in ipairs(PATH) do
		current = current:FindFirstChild(name)
		if not current then return end
		hook(current)
	end

	for _, child in ipairs(current:GetChildren()) do
		hook(child)
	end
end

enforce()

-- the game may rebuild its UI or add slots later, so catch those too
playerGui.DescendantAdded:Connect(function(inst)
	if table.find(PATH, inst.Name) or (inst.Parent and inst.Parent.Name == "Toolbar") then
		enforce()
	end
end)

-- backup check in case a change slips through
while true do
	enforce()
	task.wait(0.25)
end

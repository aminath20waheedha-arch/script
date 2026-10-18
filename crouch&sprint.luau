-- LocalScript. Needs getconnections + firesignal (executor functions).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mobileFrame = playerGui:WaitForChild("Home"):WaitForChild("hud")
	:WaitForChild("BottomRightFrame"):WaitForChild("MobileFrame")
local sprintButton = mobileFrame:WaitForChild("SprintButton")
local crouchButton = mobileFrame:WaitForChild("CrouchButton")

-- black = NOT sprinting (auto-sprint presses it). Anything else = sprinting.
local function isBlack()
	local c = sprintButton.BackgroundColor3
	return math.round(c.R * 255) == 0
		and math.round(c.G * 255) == 0
		and math.round(c.B * 255) == 0
end
local function isSprinting() return not isBlack() end

local crouched = false      -- flips every time you tap crouch
local sequenceBusy = false
local pressing = false

---------------------------------------------------------------- pressing buttons
local function fire(signal, ...)
	if typeof(firesignal) == "function" then
		pcall(firesignal, signal, ...)
	elseif typeof(getconnections) == "function" then
		local args = table.pack(...)
		pcall(function()
			for _, c in ipairs(getconnections(signal)) do
				c:Fire(table.unpack(args, 1, args.n))
			end
		end)
	end
end

local attempts = {
	{ "Activated" },
	{ "MouseButton1Click" },
	{ "MouseButton1Down", "MouseButton1Up" },
}

-- presses sprintButton until done() is true
local function pressSprintUntil(done)
	local waited = 0
	while pressing and waited < 2 do
		task.wait(0.05)
		waited += 0.05
	end
	if done() then return end

	pressing = true
	for _, names in ipairs(attempts) do
		for _, name in ipairs(names) do
			local ok, signal = pcall(function() return sprintButton[name] end)
			if ok then fire(signal) end
		end
		task.wait(0.2)
		if done() then break end
	end
	pressing = false
end

---------------------------------------------------------------- crouch intercept
local candidates = { "Activated", "MouseButton1Click", "MouseButton1Down", "TouchTap", "InputBegan" }
local originals = {}
local hooked

if typeof(getconnections) ~= "function" then
	warn("getconnections not supported, crouch intercept can't work")
else
	-- grab the game's own crouch connections BEFORE we add ours
	for _, name in ipairs(candidates) do
		local ok, signal = pcall(function() return crouchButton[name] end)
		if ok then
			local list = getconnections(signal)
			if #list > 0 then
				hooked = { name = name, signal = signal }
				for _, c in ipairs(list) do
					table.insert(originals, c)
					pcall(function() c:Disable() end)
				end
				break
			end
		end
	end

	if hooked then
		print("Intercepting crouch via " .. hooked.name)

		hooked.signal:Connect(function(...)
			local args = table.pack(...)

			-- InputBegan fires for hover etc, only react to real taps/clicks
			if hooked.name == "InputBegan" then
				local input = args[1]
				if not input or (input.UserInputType ~= Enum.UserInputType.Touch
					and input.UserInputType ~= Enum.UserInputType.MouseButton1) then
					return
				end
			end

			if sequenceBusy then return end
			sequenceBusy = true

			-- 1) unsprint first
			if isSprinting() then
				pressSprintUntil(isBlack)
			end

			-- 2) then let the game's own crouch code run
			for _, c in ipairs(originals) do
				pcall(function()
					local fn = c.Function
					if fn then
						fn(table.unpack(args, 1, args.n))
					else
						c:Fire(table.unpack(args, 1, args.n))
					end
				end)
			end

			crouched = not crouched
			sequenceBusy = false
		end)
	else
		warn("Couldn't find the game's crouch connections")
	end
end

player.CharacterAdded:Connect(function()
	crouched = false
end)

---------------------------------------------------------------- auto sprint
-- presses sprint whenever it's black, except while crouched or mid-crouch
local function autoSprint()
	if crouched or sequenceBusy or not isBlack() then return end
	pressSprintUntil(function() return not isBlack() end)
end

sprintButton:GetPropertyChangedSignal("BackgroundColor3"):Connect(autoSprint)

while true do
	autoSprint()
	task.wait(0.2)
end

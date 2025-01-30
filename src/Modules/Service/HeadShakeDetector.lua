-- HeadShakeDetector.lua
-- NirlekaDev | kurtdekker
-- January 30, 2025

--[[
	Detects if the player nods or shakes their camera.
	Original writer: kurtdekker, from Unity
]]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Signal = require("Signal")

local Config = {
	NOD = {
		REQUIRED_CYCLES = 1,          -- Number of up-down cycles needed
		ANGLE_THRESHOLD = 0.07,       -- Minimum angle change to register movement
		TIME_WINDOW = 3,             -- Time window to complete the gesture
		COOLDOWN = 0.1,              -- Minimum time between detected nods
		DIAGONAL_TOLERANCE = 0.6      -- How much diagonal movement is allowed (0-1)
	},
	SHAKE = {
		REQUIRED_CYCLES = 1,          -- Number of left-right cycles needed
		ANGLE_THRESHOLD = 0.04,       -- Minimum angle change to register movement
		TIME_WINDOW = 2,             -- Time window to complete the gesture
		COOLDOWN = 0.1,              -- Minimum time between detected shakes
		DIAGONAL_TOLERANCE = 0.6      -- How much diagonal movement is allowed (0-1)
	}
}

local HeadShakeDetector = {
	OnNod = Signal.new(),
	OnShake = Signal.new()
}

local State = {
	camera = workspace.CurrentCamera,
	tracking = false,
	nod = {
		inProgress = false,
		count = 0,
		lastAngle = 0,
		lastDirection = 0,
		timer = 0,
		cooldown = 0,
		dominantAxis = true
	},
	shake = {
		inProgress = false,
		count = 0,
		lastAngle = 0,
		lastDirection = 0,
		timer = 0,
		cooldown = 0,
		dominantAxis = true
	},
	lastPitch = 0,
	lastYaw = 0
}

local connections = {}

local function normalizeAngle(angle)
	return angle % 360
end

local function getSmallestAngleDifference(a1, a2)
	local diff = normalizeAngle(a1 - a2)
	return diff > 180 and diff - 360 or diff
end

local function getCameraAngles()
	local rx, ry, _ = State.camera.CFrame:ToEulerAnglesYXZ()
	return {
		pitch = math.deg(rx),  -- Up/down motion
		yaw = math.deg(ry)     -- Left/right motion
	}
end

local function analyzeCombinedMovement(pitchDiff, yawDiff)
	local absPitchDiff = math.abs(pitchDiff)
	local absYawDiff = math.abs(yawDiff)

	local totalMovement = absPitchDiff + absYawDiff
	if totalMovement < 0.001 then return 0, 0 end

	local pitchRatio = absPitchDiff / totalMovement
	local yawRatio = absYawDiff / totalMovement

	return pitchRatio, yawRatio
end

local function updateNodDetection(dt)
	local state = State.nod
	local config = Config.NOD

	if state.cooldown > 0 then
		state.cooldown = state.cooldown - dt
		return
	end

	if state.inProgress then
		state.timer = state.timer + dt
		if state.timer > config.TIME_WINDOW then
			state.inProgress = false
			state.count = 0
			return
		end
	end

	local angles = getCameraAngles()
	local pitchDiff = angles.pitch - state.lastAngle
	local yawDiff = getSmallestAngleDifference(angles.yaw, State.lastYaw)

	local pitchRatio, yawRatio = analyzeCombinedMovement(pitchDiff, yawDiff)

	if pitchRatio >= config.DIAGONAL_TOLERANCE and math.abs(pitchDiff) >= config.ANGLE_THRESHOLD then
		local direction = pitchDiff > 0 and 1 or -1

		if direction ~= state.lastDirection then
			state.lastDirection = direction
			state.count = state.count + 0.5

			if not state.inProgress then
				state.inProgress = true
				state.timer = 0
			end

			if state.count >= config.REQUIRED_CYCLES then
				warn("Yes!")
				HeadShakeDetector.OnNod:Fire()
				state.inProgress = false
				state.count = 0
				state.cooldown = config.COOLDOWN
			end
		end
	end

	state.lastAngle = angles.pitch
end

local function updateShakeDetection(dt)
	local state = State.shake
	local config = Config.SHAKE

	if state.cooldown > 0 then
		state.cooldown = state.cooldown - dt
		return
	end

	if state.inProgress then
		state.timer = state.timer + dt
		if state.timer > config.TIME_WINDOW then
			state.inProgress = false
			state.count = 0
			return
		end
	end

	local angles = getCameraAngles()
	local pitchDiff = angles.pitch - State.lastPitch
	local yawDiff = getSmallestAngleDifference(angles.yaw, state.lastAngle)

	local pitchRatio, yawRatio = analyzeCombinedMovement(pitchDiff, yawDiff)

	if yawRatio >= config.DIAGONAL_TOLERANCE and math.abs(yawDiff) >= config.ANGLE_THRESHOLD then
		local direction = yawDiff > 0 and 1 or -1

		if direction ~= state.lastDirection then
			state.lastDirection = direction
			state.count = state.count + 0.5

			if not state.inProgress then
				state.inProgress = true
				state.timer = 0
			end

			if state.count >= config.REQUIRED_CYCLES then
				warn("No!")
				HeadShakeDetector.OnShake:Fire()
				state.inProgress = false
				state.count = 0
				state.cooldown = config.COOLDOWN
			end
		end
	end

	state.lastAngle = angles.yaw
	State.lastPitch = angles.pitch
	State.lastYaw = angles.yaw
end

function HeadShakeDetector._ready()
	local camera: Camera = workspace.CurrentCamera
	for i2, master in pairs(Config) do
		for i, config in pairs(master) do
			local name = string.format("%s_%s", i2, i)
			camera:SetAttribute(name, config)
			connections[#connections+1] = camera:GetAttributeChangedSignal(name):Connect(function()
				Config[i2][i] = camera:GetAttribute(name)
			end)
		end
	end
end

function HeadShakeDetector._run(dt)
	if State.tracking then
		updateNodDetection(dt)
		updateShakeDetection(dt)
	end
end

function HeadShakeDetector.SetDetection(bool: boolean)
	State.tracking = bool
end

return HeadShakeDetector
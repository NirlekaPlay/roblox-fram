-- HeadShakeDetector.lua
-- NirlekaDev | kurtdekker
-- January 30, 2025

--[[
	Detects if the player nods or shakes their camera.
	Original writer: kurtdekker, from Unity
]]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Signal = require("Signal")
local camera = workspace.CurrentCamera or workspace.Camera

local nod_count_required = 6
local nod_angular_requirement = 3
local nod_timing_requirement = 0.75
local nod_inProgress = 0
local nod_count = 0
local last_significant_nod_angle = 0
local last_digital_nod = 0

local shake_count_required = 6
local shake_angular_requirement = 3
local shake_timing_requirement = 0.50

local shake_in_progress = 0
local last_significant_shake_angle = 0
local last_digital_shake = 0
local shake_count = 0

local HeadShakeDetector = {}
HeadShakeDetector.OnNod = Signal.new()
HeadShakeDetector.OnShake = Signal.new()

function HeadShakeDetector._run(dt)
	HeadShakeDetector.updateNodYes(dt)
	HeadShakeDetector.updateShakeNo(dt)
end

function HeadShakeDetector.updateNodYes(dt: number)
	if nod_inProgress > 0 then
		nod_inProgress -= dt
		if nod_inProgress <= 0 then
			nod_count = 0
			last_digital_nod = 0
		end
	end

	local forward_y = camera.CFrame.LookVector.Y
	local angle = math.asin(forward_y) * 360 / (math.pi * 2)

	local nod = 0
	if angle < (last_significant_nod_angle - nod_angular_requirement) then
		nod = -1
		last_significant_nod_angle = angle
	else
		if angle > (last_significant_nod_angle + nod_angular_requirement) then
			nod = 1
			last_significant_nod_angle = angle
		end
	end

	if nod ~= 0 then
		if nod ~= last_digital_nod then
			last_digital_nod = nod
			nod_count += 1

			nod_inProgress = nod_timing_requirement

			if nod_count >= nod_count_required then
				nod_count = 0

				--yes!
				print("Yes!")
				HeadShakeDetector.OnNod:Fire()
			end
		end
	end
end

function HeadShakeDetector.updateShakeNo(dt: number)
	if shake_in_progress > 0 then
		shake_in_progress = shake_in_progress - dt
		if shake_in_progress <= 0 then
			shake_count = 0
			last_digital_shake = 0
		end
	end

	local angle = camera.CFrame.LookVector.Y

	local shake = 0
	local deltaAngle = math.deg(math.atan2(math.sin(math.rad(angle - last_significant_shake_angle)), math.cos(math.rad(angle - last_significant_shake_angle))))

	if deltaAngle < -shake_angular_requirement then
		shake = -1
		last_significant_shake_angle = angle
	elseif deltaAngle > shake_angular_requirement then
		shake = 1
		last_significant_shake_angle = angle
	end

	if shake ~= 0 then
		if shake ~= last_digital_shake then
			last_digital_shake = shake
			shake_count = shake_count + 1

			shake_in_progress = shake_timing_requirement

			if shake_count >= shake_count_required then
				shake_count = 0

				--no!
				print("No!")
				HeadShakeDetector.OnShake:Fire()
			end
		end
	end
end

return HeadShakeDetector

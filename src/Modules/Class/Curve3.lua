-- Curve3.lua
-- Nirleka | Nico
-- January 13, 2024

--[[
	Animates the camera using curves and pathways that I s̶t̶o̶l̶e̶ one of Nico's old project with Monaterop.
	Anyways, thanks for making my life more easier :D
]]

local RunService = game:GetService("RunService")

local Curve3 = {}

local cameraPositions = Curve3.setupWaypoints(workspace.CurrentCamera, workspace.cameras)

function Curve3.new()
	local self = setmetatable({}, Curve3)

	return self
end

function Curve3.setupWaypoints(targetPart: BasePart, waypoints: {BasePart})
	local currentCFrame = targetPart.CFrame
	local cameraPositions = {}
	local cameraRotations = {}

	table.sort(waypoints, function(a,b)
		if tonumber(a.Name) < tonumber(b.Name) then
			return true
		end
	end)

	for _, cam in pairs(waypoints) do
		table.insert(cameraPositions,cam.PrimaryPart.CFrame)
		table.insert(cameraRotations,cam.PrimaryPart.CFrame.LookVector)
		cam:Destroy()
	end

	targetPart.CFrame = cameraPositions[1]
	return cameraPositions, cameraRotations, currentCFrame
end

function Curve3.createCurve(values: {})
	local curve = Instance.new("Vector3Curve")
	local xCurve, yCurve, zCurve = curve:X(), curve:Y(), curve:Z()

	for i, value in ipairs(values) do
		xCurve:InsertKey(FloatCurveKey.new(i, value.X))
		yCurve:InsertKey(FloatCurveKey.new(i, value.Y))
		zCurve:InsertKey(FloatCurveKey.new(i, value.Z))
	end

	return curve
end

function Curve3.getCFrameCurves(cameraPositions, cameraRotations)
	table.insert(cameraPositions, cameraPositions[1]) -- Preserving initial positions
	table.insert(cameraPositions, cameraPositions[2]) -- Preserving second position
	table.insert(cameraRotations, cameraRotations[1]) -- Preserving initial rotations
	table.insert(cameraRotations, cameraRotations[2]) -- Preserving second rotation

	local posCurve1 = Curve3.createCurve(cameraPositions)
	local posCurve2 = Curve3.createCurve(cameraPositions)
	local rotCurve1 = Curve3.createCurve(cameraRotations)
	local rotCurve2 = Curve3.createCurve(cameraRotations)

	return posCurve1, posCurve2, rotCurve1, rotCurve2
end

function Curve3._animateCamera()
	local posCurve1, posCurve2, rotCurve1, rotCurve2 = getCFrameCurves()

	while true do
		for currentCycle = 1, #cameraPositions - 2 do
			for _, curveData in ipairs({
				{posCurve1, rotCurve1, currentCycle},
				{posCurve2, rotCurve2, currentCycle + 1},
			}) do
				local posCurve, rotCurve, cycleIndex = unpack(curveData)

				for index = 0, 1, (1 / 120) do
					local currentPosition = Vector3.new(table.unpack(posCurve:GetValueAtTime(index + cycleIndex)))
					local currentRotation = Vector3.new(table.unpack(rotCurve:GetValueAtTime(index + cycleIndex)))
					local Cframe = CFrame.lookAt(currentPosition, currentPosition + currentRotation)

					currentCamera.CFrame = Cframe
					if index ~= 0 then
						task.wait()
					end
				end
			end
		end
	end
end

function Curve3.animateCamera(targetPart)
	local posCurve1, posCurve2, rotCurve1, rotCurve2 = Curve3.getCFrameCurves()
	local isAnimating = true
	local cameraStartTime = 0
	local cycleDuration = 1
	local currentCycle = 1

	local function getLerpedValue(startValue, endValue, alpha)
		return startValue:Lerp(endValue, alpha)
	end

	local function getCurveValue(curve, startIndex, endIndex, alpha)
		local startValue = Vector3.new(table.unpack(curve:GetValueAtTime(startIndex)))
		local endValue = Vector3.new(table.unpack(curve:GetValueAtTime(endIndex)))
		return getLerpedValue(startValue, endValue, alpha)
	end

	RunService.RenderStepped:Connect(function(deltaTime)
		if not isAnimating then return end

		local elapsedTime = tick() - cameraStartTime
		local alpha = math.clamp(elapsedTime / cycleDuration, 0, 1)

		local posCurve = currentCycle % 2 == 1 and posCurve1 or posCurve2
		local rotCurve = currentCycle % 2 == 1 and rotCurve1 or rotCurve2

		local currentPosition = getCurveValue(posCurve, currentCycle, currentCycle + 1, alpha)
		local currentRotation = getCurveValue(rotCurve, currentCycle, currentCycle + 1, alpha)

		targetPart.CFrame = CFrame.lookAt(currentPosition, currentPosition + currentRotation)

		if elapsedTime >= cycleDuration then
			cameraStartTime = tick() -- Reset start time for the next cycle
			currentCycle = currentCycle + 1

			-- Loop back to the beginning if at the end
			if currentCycle >= #cameraPositions - 2 then
				currentCycle = 1
			end
		end
	end)
end

return Curve3
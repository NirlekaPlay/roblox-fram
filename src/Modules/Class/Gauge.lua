-- Gauge.lua
-- NirlekaDev
-- December 25, 2024

local Gauge = {}
Gauge.__index = Gauge

function Gauge.new(model: Model, maxValue: number, maxDegrees: number, needleSpeed: number)
	local self = setmetatable({
		_model = model,
		_maxValue = maxValue,
		_maxDeg = maxDegrees,
		_needleSpeed = needleSpeed,
		_currentRotation = Vector3.new()
	}, Gauge)
	return self
end

function Gauge:_run()
	self:LerpNeedle()
end

function Gauge:CalculateNeedleRotation(pressureBars: number)
	pressureBars = math.clamp(pressureBars, 0, self._maxValue)
	local rotationAngle = (pressureBars / self._maxValue) * self._maxDeg
	self._currentRotation = Vector3.new(rotationAngle, 0, 0)
end

function Gauge:LerpNeedle()
	local needle: BasePart = self._model.Model.Needle
	needle.Rotation:Lerp(self._currentRotation, self._needleSpeed)
end

return Gauge
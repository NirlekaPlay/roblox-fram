-- Camera.lua
-- Nirleka Dev
-- November 23, 2024

--[[
	A class for cameras.
]]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local SmoothValue = require("SmoothValue")
local mouse = game.Players.LocalPlayer:GetMouse()

local function lerp(a, b, t)
	return a + (b - a) * t
end

function easeInOutCubic(t: number)
	if t < 0.5 then
		return 4 * t^3
	else
		return 1 - (-2 * t + 2)^3 / 2
	end
end

local Camera = {}
Camera.__index = Camera

function Camera.new(cam: Camera)
	local self = setmetatable({}, Camera)

	self.Camera = cam

	self.currentSocket = nil
	self.currentCframe = cam.CFrame
	self.currentFov = cam.FieldOfView
	self.moving = false
	self.mouseHover = false
	self.elapsed = 0
	self.duration = 5

	self.maxTilt = 15
	self.smoothTime = 1
	self.smoothTiltX = SmoothValue.new(Vector3.new(0, 0, 0), self.smoothTime)
	self.smoothTiltY = SmoothValue.new(Vector3.new(0, 0, 0), self.smoothTime)

	return self
end

function Camera:_run(dt)
	self:MoveToMouse()
	self:LerpMovement(dt)
end

function Camera:Setup()
	if self.Camera.CameraType == Enum.CameraType.Scriptable then return end
	repeat
		task.wait()
		self.Camera.CameraType = Enum.CameraType.Scriptable
	until self.Camera.CameraType == Enum.CameraType.Scriptable

	self.Camera:GetPropertyChangedSignal("CameraType"):Connect(function()
		Camera:Setup()
	end)
end

function Camera:Reset()
	self.Camera.CameraType = Enum.CameraType.Custom
end

function Camera:BeginLerp(camSocket: {})
	self.currentSocket = camSocket
	self.currentCframe = self.Camera.CFrame
	self.currentFov = self.Camera.FieldOfView
	self.elapsed = 0
	self.moving = true
end

function Camera:LerpMovement(dt: number)
	if self.moving then
		self.elapsed += dt
		local c = easeInOutCubic(math.clamp(self.elapsed / self.duration, 0.0, 1.0))
		self.Camera.CFrame = self.Camera.CFrame:Lerp(self.currentSocket.cframe, c)
		self.Camera.FieldOfView = lerp(self.currentFov, self.currentSocket.fov, c)

		if self.Camera.CFrame == self.currentSocket.cframe and
			self.Camera.FieldOfView == self.currentSocket.fov then
			self.moving = false
		end
	end
end

function Camera:MoveToMouse()
	if self.mouseHover then
		local maxTilt = self.maxTilt
		local smoothTiltX = self.smoothTiltX
		local smoothTiltY = self.smoothTiltY

		local goalTiltX = (((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY) * -maxTilt)
		local goalTiltY = (((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX) * -maxTilt)

		local smoothX = smoothTiltX:Update(Vector3.new(math.rad(goalTiltX), 0, 0))
		local smoothY = smoothTiltY:Update(Vector3.new(0, math.rad(goalTiltY), 0))

		self.Camera.CFrame = self.currentSocket.cframe * CFrame.Angles(
			smoothX.X,
			smoothY.Y,
			0
		)
	end
end

return Camera
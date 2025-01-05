-- Valve.lua
-- NirlekaDev
-- January 2, 2024

local UserInputService = game:GetService("UserInputService")
local ButtonClass = require(game.Players.LocalPlayer.PlayerScripts.Client.Modules.ButtonClass)

local Valve = {}
Valve.__index = Valve

function Valve.new(valvePart: BasePart, speed: number)
	local self = setmetatable({}, Valve)

	self.valvePart = valvePart
	self.speed = speed or 300
	self.rotation = 0
	self.rotating = false
	self.initialMousePosition = nil
	self._button = ButtonClass.new(valvePart)

	self:_ready()

	return self
end

function Valve:_ready()
	self._button.MouseButton1Click:Connect(function()
		self:BeginRotate()
	end)
	self._button.MouseButton1Lift:Connect(function()
		self:StopRotating()
	end)
end

function Valve:_run()
	self:RotateValve()
end

function Valve:BeginRotate()
	self.rotating = true
	self.initialMousePosition = UserInputService:GetMouseLocation().X
end

function Valve:RotateValve()
	if self.rotating then
		local currentMousePosition = UserInputService:GetMouseLocation().X
		local screenWidth = workspace.CurrentCamera.ViewportSize.X
		local mouseMovement = (currentMousePosition - self.initialMousePosition) / screenWidth

		self.rotation += (mouseMovement * self.speed)

		if self.rotation >= 360 then
			self.rotation = 360
			return
		elseif self.rotation <= 0 then
			self.rotation = 0
			return
		end

		self.valvePart.CFrame = self.valvePart.CFrame * CFrame.Angles(0, 0, math.rad(mouseMovement * self.speed))
		self.initialMousePosition = currentMousePosition
	end
end

function Valve:StopRotating()
	self.rotating = false
	if self.rotation >= 360 then
		self.rotation = 360
		return
	elseif self.rotation <= 0 then
		self.rotation = 0
		return
	end
end

return Valve
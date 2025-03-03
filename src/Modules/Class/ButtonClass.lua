-- ButtonClass.lua
-- NirlekaDev
-- January 5, 2025

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local Input = require("Input")
local CursorManager = require("CursorManager")
local Maid = require("Maid")
local Signal = require("Signal")

local ButtonClass = {}
ButtonClass.__index = ButtonClass

function ButtonClass.new(parent: Instance)
	local self = setmetatable({}, ButtonClass)

	self.parent = parent
	self.isActive = true
	self.clickDetector = Instance.new("ClickDetector", parent)
	self.mouseHovered = false
	self._maid = Maid.new()

	self.MouseButton1Click = Signal.new()
	self.MouseButton1Lift = Signal.new()

	self:_bind_methods()

	self.__newindex = function(t, i, v)
		rawset(t, i, v)
		if i == "isActive" then
			if (not self.isActive) and self.mouseHovered then
				CursorManager.SetCursorImage("invalid")
			end
		end
	end

	return self
end

function ButtonClass:_bind_methods()
	local clickDetector = self.clickDetector

	self._maid:GiveTasksArray({
		self.MouseButton1Click,
		self.MouseButton1Lift,
		clickDetector,
		clickDetector.MouseHoverEnter:Connect(function()
			self:OnHover()
		end),
		clickDetector.MouseHoverLeave:Connect(function()
			self:OnLeave()
		end),
		Input.ListenKeyPress(Enum.UserInputType.MouseButton1):Connect(function()
			if self._mouseHovered then
				self.MouseButton1Click:Fire()
			end
		end),
		Input.ListenKeyLift(Enum.UserInputType.MouseButton1):Connect(function()
			self.MouseButton1Lift:Fire()
		end)
	})
end

function ButtonClass:OnHover()
	if self.isActive and Input.IsInputEnabled() then
		self._mouseHovered = true
		CursorManager.SetCursorImage("hover")
	else
		CursorManager.SetCursorImage("invalid")
	end
end

function ButtonClass:OnLeave()
	self._mouseHovered = false
	CursorManager.SetCursorImage("point")
end

function ButtonClass:Destroy()
	if self._mouseHovered then
		CursorManager.SetCursorImage("point")
	end
	self._maid:DoCleaning()
	setmetatable(self, nil)
end

return ButtonClass
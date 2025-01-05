-- ButtonClassBranch.lua
-- NirlekaDev
-- January 5, 2025

local Control = require(game.Players.LocalPlayer.PlayerScripts.Client.Modules.Control)
local CursorManager = require(game.Players.LocalPlayer.PlayerScripts.Client.Managers.CursorManager)
local Signal = require(game.Players.LocalPlayer.PlayerScripts.Client.Library.Signal)

local ButtonClass = {}
ButtonClass.__index = ButtonClass

function ButtonClass.new(parent: Instance)
	local self = setmetatable({}, ButtonClass)

	self.parent = parent
	self.isActive = true
	self._clickDetector = Instance.new("ClickDetector", parent)
	self._mouseHovered = false
	self._connections = {}

	self.MouseButton1Click = Signal.new()
	self.MouseButton1Lift = Signal.new()

	self:Setup()

	return self
end

function ButtonClass:Setup()
	local clickDetector: ClickDetector = self._clickDetector
	local connections = self._connections

	connections[#connections+1] = clickDetector.MouseHoverEnter:Connect(function() self:OnHover() end)
	connections[#connections+1] = clickDetector.MouseHoverLeave:Connect(function() self:OnLeave() end)
	connections[#connections+1] = Control.ListenKeyPress(Enum.UserInputType.MouseButton1):Connect(function()
		if self._mouseHovered then
			self.MouseButton1Click:Fire()
		end
	end)
	connections[#connections+1] = Control.ListenKeyLift(Enum.UserInputType.MouseButton1):Connect(function()
		self.MouseButton1Lift:Fire()
	end)
end

function ButtonClass:OnHover()
	if self.isActive and Control.IsInputEnabled() then
		self._mouseHovered = true
		CursorManager.SetCursorImage("hover")
	end
end

function ButtonClass:OnLeave()
	if self.isActive and Control.IsInputEnabled() then
		self._mouseHovered = false
		CursorManager.SetCursorImage("point")
	end
end

function ButtonClass:Destroy()
	for _, connection in pairs(self._connections) do
		connection:Disconnect()
		connection:Destroy()
	end
	self._clickDetector:Destroy()
	setmetatable(self, nil)
end

return ButtonClass
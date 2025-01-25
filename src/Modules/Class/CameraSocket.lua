-- CameraSocket.lua
-- Nirleka Dev
-- November 28, 2024

--[[
	A camera socket is a predefined point in space with attirbutes like CFrames and FieldofView.
	Used to facilitate camera transitions.
]]

local CameraSocket = {}
CameraSocket.__index = CameraSocket

function CameraSocket.new(name: string, cframe: CFrame, fov: number)
	local self = setmetatable({}, CameraSocket)

	self.socketName = name
	self.cframe = cframe
	self.fov = fov

	return self
end

function CameraSocket.fromPart(part: BasePart, fov: number)
	fov = fov or 70
	return CameraSocket.new(part.Name, part.CFrame, fov)
end

function CameraSocket.fromArray(array: {BasePart})
	local socketTable = {}

	for i, part in pairs(array) do
		local newSocket = CameraSocket.fromPart(part, part:GetAttribute("fov"))
		socketTable[i] = newSocket
	end

	return socketTable
end

return CameraSocket
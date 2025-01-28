--[[
		// FileName: CursorManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages the mouse cursor,
				including the icon, and it's behaviour.

				CLIENT ONLY.
]]

local UserInputService = game:GetService("UserInputService")

local images = game.ReplicatedStorage.Images
local sound: Sound = game.SoundService.Isolated.beep
local cursor_point : ImageLabel = images.mouse_point
local cursor_hover : ImageLabel = images.mouse_hover
local cursor_invalid : ImageLabel = images.mouse_invalid
local cursor_icons = {cursor_point, cursor_hover, cursor_invalid}
local cursor_visible = false
local cursor_lock_center = true

local CursorManager = {}

function CursorManager._ready()
	CursorManager.SetCursor(false, false)
	CursorManager.SetCursorImage("point")
	CursorManager.SetCursorLock(true)
end

function CursorManager._run()
	if cursor_lock_center then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

function CursorManager.SetCursor(isVisible: boolean, playSound: boolean)
	cursor_visible = isVisible
	UserInputService.MouseIconEnabled = isVisible
	if playSound then
		sound:Play()
	end
end

function CursorManager.SetCursorLock(booelan)
	cursor_lock_center = booelan
	if not booelan then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

function CursorManager.SetCursorImage(alias: string)
	for _, icon in pairs(cursor_icons) do
		if string.find(icon.Name, alias) then
			UserInputService.MouseIcon = icon.Texture
			return
		end
	end
end

return CursorManager
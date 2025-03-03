--[[
		// FileName: CursorManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages the mouse cursor,
				including the icon, and it's behaviour.

				CLIENT ONLY.
]]

local UserInputService = game:GetService("UserInputService")
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local ssp2d = require("SoundStreamPlayer2D")

local images = game.ReplicatedStorage.Images
local speaker_mouseShow = ssp2d.new(game.SoundService.Isolated.swipe)
local cursor_icons = {
	point = images.mouse_point,
	hover = images.mouse_hover,
	invalid = images.mouse_invalid
}
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
		speaker_mouseShow:Play()
	end
end

function CursorManager.SetCursorLock(booelan)
	cursor_lock_center = booelan
	if not booelan then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

function CursorManager.SetCursorImage(alias: string)
	local icon = cursor_icons[alias]
	if not icon then
		return
	end
	UserInputService.MouseIcon = icon.Texture
end

return CursorManager
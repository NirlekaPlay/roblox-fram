-- CursorManager.lua
-- NirlekaDev
-- December 5, 2024

local UserInputService = game:GetService("UserInputService")

local images = game.Players.LocalPlayer.PlayerScripts.Client.Images
local sound: Sound = game.SoundService.Isolated.mouse_show
local cursor_point : ImageLabel = images.mouse_point
local cursor_hover : ImageLabel = images.mouse_hover
local cursor_invalid : ImageLabel = images.mouse_invalid
local cursor_icons = {cursor_point, cursor_hover, cursor_invalid}
local cursor_visible = false

local CursorManager = {}

function CursorManager._ready()
	CursorManager.SetCursor(false, false)
end

function CursorManager.SetCursor(isVisible: boolean, playSound: boolean)
	cursor_visible = isVisible
	UserInputService.MouseIconEnabled = isVisible
	if playSound then
		sound:Play()
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
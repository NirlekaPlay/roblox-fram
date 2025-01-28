--[[
		// FileName: ChapterTextManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages the chapter text animation.

				CLIENT ONLY.
]]

local TweenService = game:GetService("TweenService")

local ui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Chapter").root
local chapter_number_text: TextLabel = ui.backdrop1.text
local chapter_number_gradient: UIGradient = chapter_number_text.UIGradient
local chapter_title_text: TextLabel = ui.backdrop.text
local chapter_title_gradient: UIGradient = chapter_title_text.UIGradient

local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local array_gradients = {chapter_number_gradient, chapter_title_gradient}
local gradient_rotation_value = -50
local current_title = ""
local current_number = 0

local ChapterText = {}

function ChapterText.ShowText(number: number, title: string, durationStart: number)
	current_number = number
	current_title = title
	chapter_number_text.Text = "CHAPTER "..tostring(number)
	chapter_title_text.Text = title

	for _, gradient: UIGradient in ipairs(array_gradients) do
		gradient.Rotation = gradient_rotation_value
		task.spawn(function()
			TweenService:Create(gradient, tweenInfo, {Rotation = -20}):Play()
		end)
	end
	task.wait(durationStart)
	for _, gradient: UIGradient in ipairs(array_gradients) do
		task.spawn(function()
			TweenService:Create(gradient, tweenInfo, {Rotation = -180}):Play()
		end)
	end
end

return ChapterText
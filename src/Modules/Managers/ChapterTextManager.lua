--[[
		// FileName: ChapterTextManager.lua
		// Written by: NirlekaDev
		// Description:
				Manages the chapter text animation.

				CLIENT ONLY.
]]

local TweenService = game:GetService("TweenService")

local ui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Chapter").root
local chapter_number_text: TextLabel = ui.frame_chapterNum.text
local chapter_number_backdrop: TextLabel = ui.frame_chapterNum.text_backdrop
local chapter_number_gradient: UIGradient = chapter_number_text.UIGradient
local chapter_title_text: TextLabel = ui.frame_chapterTitle.text
local chapter_title_backdrop: TextLabel = ui.frame_chapterTitle.text_backdrop
local chapter_title_gradient: UIGradient = chapter_title_text.UIGradient

local array_chapters_text = {chapter_number_text, chapter_title_text, chapter_number_backdrop, chapter_title_backdrop}
local array_gradients = {chapter_number_gradient, chapter_title_gradient}
local array_backdrops = {chapter_number_backdrop, chapter_title_backdrop}
local gradient_rotation_value_start = -62
local gradient_rotation_value_end = 115
local current_title = ""
local current_number = 0

local ChapterText = {}

function ChapterText.BeginShowChapter(number: number, title: string, durationStart: number)
	current_number = number
	current_title = title
	for _, text: TextLabel in ipairs(array_chapters_text) do
		if text.Parent.Name:find("Num") then
			text.Text = "CHAPTER "..tostring(number)
		else
			text.Text = title
		end
	end

	ChapterText.ShowText()
	task.wait(durationStart)
	ChapterText.HideText()
end

function ChapterText.ShowText()
	for i, gradient: UIGradient in ipairs(array_gradients) do
		gradient.Rotation = gradient_rotation_value_start
		local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		array_backdrops[i].TextTransparency = 0
		TweenService:Create(gradient, tweenInfo, {Rotation = -20}):Play()
	end
end

function ChapterText.HideText()
	for _, gradient: UIGradient in ipairs(array_gradients) do
		gradient.Rotation = gradient_rotation_value_end
		local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(gradient, tweenInfo, {Rotation = 180}):Play()
	end
	for _, backdrop: TextLabel in ipairs(array_backdrops) do
		local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(backdrop, tweenInfo, {TextTransparency = 1}):Play()
	end
end

return ChapterText
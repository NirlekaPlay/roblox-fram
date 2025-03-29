--[[
		// FileName: DialogueManager.lua
		// Written by: NirlekaDev | Mike
		// Description:
						Manages the text of the dialogue UI.

				CLIENT ONLY.
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local Tween = require("Tween")
local ssp2d = require("SoundStreamPlayer2D")
local randf_range = require("math").randf_range

local ui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Dialogue").root
local ui_dialogue_text = ui.dialogue_backdrop.text
local ui_dialogue_backdrop = ui.dialogue_backdrop
local speaker_click = ssp2d.new(SoundService.Isolated.dialogue)

local tweens_ui_dialogue = Tween.new():SetTrans(Tween["ENUM_TRANSITION_TYPES"]["TRANS_CUBIC"])
	:SetEase(Tween["ENUM_EASING_TYPES"]["EASE_IN_OUT"])

local function create_tween(current_tween, trans_type, ease_type)
	if current_tween then
		trans_type = current_tween:GetTrans()
		ease_type = current_tween:GetEase()

		current_tween:Kill()
		current_tween:Destroy()
	end

	current_tween = Tween.new():SetTrans(trans_type):SetEase(ease_type)
	return current_tween
end

local DialogueManager = {}

function DialogueManager.HideDialogue()
	local tween = create_tween(tweens_ui_dialogue):SetParallel(true)
	tween:TweenProperty(ui_dialogue_text, "TextTransparency", 1, 1)
	tween:TweenProperty(ui_dialogue_backdrop, "Transparency", 1, 1)
end

function DialogueManager.ShowDialogue()
	local tween = create_tween(tweens_ui_dialogue):SetParallel(true)
	tween:TweenProperty(ui_dialogue_text, "TextTransparency", 0, 1)
	tween:TweenProperty(ui_dialogue_backdrop, "Transparency", 0, 1)
end

function DialogueManager.StepText(text: string, charPerSe: number)
	ui_dialogue_text.Text = "" -- Reset text
	local totalLength = #text
	local index = 1
	local timePerCharacter = 1 / charPerSe -- Time per character
	local elapsedTime = 0

	while index <= totalLength do
		local deltaTime = RunService.RenderStepped:Wait()
		elapsedTime = elapsedTime + deltaTime

		while elapsedTime >= timePerCharacter and index <= totalLength do
			local visibleText = string.sub(text, 1, index) -- Fully visible text
			local nextChar = string.sub(text, index + 1, index + 1) -- Next character
			local nextCharDisplay = ""

			-- If there's a next character, show it with transparency
			if nextChar ~= "" then
				nextCharDisplay = string.format('<font transparency="%.1f">%s</font>', ghostTransparency, nextChar)
			end

			-- Update TextLabel with Rich Text
			textLabel.Text = visibleText .. nextCharDisplay

			index = index + 1
			elapsedTime = elapsedTime - timePerCharacter
		end
	end
end

return DialogueManager
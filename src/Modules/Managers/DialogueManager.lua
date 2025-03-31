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
		current_tween = nil
	end

	--current_tween:Destroy()

	current_tween = Tween.new():SetTrans(trans_type):SetEase(ease_type)
	return current_tween
end

local BASE_DELAYS = {
	["."] = 0.3,
	[","] = 0.2,
	["|"] = 1.0
}

local function playSound()
	speaker_click.pitch_scale = randf_range(0.2, 0.6)
	speaker_click:Play()
end

local function processFormatting(text)
	local segments = {}
	local currentIndex = 1

	while currentIndex <= #text do
		local startUnderscore = text:find("_", currentIndex)

		if startUnderscore then
			if startUnderscore > currentIndex then
				table.insert(segments, {
					text = text:sub(currentIndex, startUnderscore - 1),
					skip = false
				})
			end

			local endUnderscore = text:find("_", startUnderscore + 1)
			if endUnderscore then
				local word = text:sub(startUnderscore + 1, endUnderscore - 1)

				local nextCharIndex = endUnderscore + 1
				local spaces = ""
				while nextCharIndex <= #text and text:sub(nextCharIndex, nextCharIndex) == " " do
					spaces = spaces .. " "
					nextCharIndex = nextCharIndex + 1
				end

				table.insert(segments, {
					text = word .. spaces,
					skip = true
				})

				currentIndex = nextCharIndex
			else
				table.insert(segments, {
					text = text:sub(currentIndex),
					skip = false
				})
				break
			end
		else
			table.insert(segments, {
				text = text:sub(currentIndex),
				skip = false
			})
			break
		end
	end

	return segments
end

local function calculatePauseDuration(text, index)
	local char = text:sub(index, index)

	if char == "|" then
		local count = 0
		local i = index
		while i <= #text and text:sub(i, i) == "|" do
			count = count + 1
			i = i + 1
		end
		return BASE_DELAYS["|"] * count, count, true
	end

	if char == "." then
		local count = 0
		local i = index
		while i <= #text and text:sub(i, i) == "." do
			count = count + 1
			i = i + 1
		end
		return BASE_DELAYS["."] * count, 1, false
	end

	if char == "," then
		return BASE_DELAYS[","], 1, false
	end

	return 0, 1, false
end

local function cleanText(text)
	text = text:match("^%s*(.-)%s*$")
	text = text:gsub("%s+", " ")
	return text
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

function DialogueManager.StepText(label, text, cps, fadeTime, maxFades)

	label.Text = ""
	local characters = {}
	local charDelay = 1/cps

	-- Pre-process all characters
	for i = 1, #text do
		characters[i] = {
			char = text:sub(i,i),
			state = "pending", -- pending/fading/visible
			progress = 0,
			startTime = nil
		}
	end

	local startTime = tick()
	local lastCharTime = 0
	local nextCharIndex = 1

	while true do
		local currentTime = tick() - startTime
		local needsUpdate = false

		-- Add new characters when it's their turn
		while nextCharIndex <= #characters and currentTime >= lastCharTime + charDelay do
			characters[nextCharIndex].state = "fading"
			characters[nextCharIndex].startTime = tick()
			lastCharTime = lastCharTime + charDelay
			nextCharIndex = nextCharIndex + 1
			needsUpdate = true
		end

		-- Update fading characters
		local activeFades = 0
		for i = 1, #characters do
			local char = characters[i]

			if char.state == "fading" then
				activeFades = activeFades + 1
				char.progress = math.min(1, (tick() - char.startTime)/fadeTime)

				if char.progress >= 1 then
					char.state = "visible"
				end
				needsUpdate = true

				-- Enforce max simultaneous fades
				if activeFades >= maxFades then
					break
				end
			end
		end

		-- Only rebuild text if something changed
		if needsUpdate then
			local visibleText = ""
			local fadingText = ""

			for i = 1, #characters do
				local char = characters[i]

				if char.state == "visible" then
					visibleText = visibleText .. char.char
				elseif char.state == "fading" then
					fadingText = fadingText .. string.format('<font transparency="%.2f">%s</font>', 1-char.progress, char.char)
				end
			end

			label.Text = visibleText .. fadingText
		end

		-- Exit condition
		if nextCharIndex > #characters then
			local allVisible = true
			for _, char in ipairs(characters) do
				if char.state ~= "visible" then
					allVisible = false
					break
				end
			end

			if allVisible then
				label.Text = text -- Final perfect display
				break
			end
		end

		task.wait()
	end
end

return DialogueManager
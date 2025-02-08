--[[
		// FileName: DialogueManager.lua
		// Written by: NirlekaDev | Mike
		// Description:
						Manages the text of the dialogue UI.

				CLIENT ONLY.
]]

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local ssp2d = require("SoundStreamPlayer2D")
local randf_range = require("math").randf_range

local ui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Dialogue").root
local speaker_click = ssp2d.new(SoundService.Isolated.dialogue)
local dialogueUI = ui.dialogue_backdropUI.text
local dialogueUI_backdrop = ui.dialogue_backdropUI

local current_text = ""
local incrementDelay = 0.05
local looping = false

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

function DialogueManager.ShowText_ForDuration(activeText, showDuration)
	DialogueManager.ShowText_Forever(activeText)
	task.wait(showDuration)
	DialogueManager.HideDialogue()
end

function DialogueManager.ShowText_Forever(activeText)
	DialogueManager.ShowDialogue()
	dialogueUI.Text = activeText
	current_text = activeText
	looping = true
	DialogueManager.TickText()
end

function DialogueManager.HideDialogue()
	looping = false
	dialogueUI.Visible = false
	dialogueUI_backdrop.Visible = false
end

function DialogueManager.ShowDialogue()
	looping = false
	dialogueUI.Visible = true
	dialogueUI_backdrop.Visible = true
end

function DialogueManager.Skip()
	if looping then
		DialogueManager.HideDialogue()
	end
end

function DialogueManager.PlaySequence(sequenceText)
	local dialogues = string.split(sequenceText, "\n")

	for _, dialogue in ipairs(dialogues) do
		dialogue = cleanText(dialogue)

		if dialogue == "" then
			continue
		end

		local waitTime, text = dialogue:match("([%d%.]+)%s+(.+)$")

		if waitTime and text then
			waitTime = tonumber(waitTime)
			local duration, actualText = text:match("@([%d%.]+)%s+(.+)$")

			if duration then
				duration = tonumber(duration)
				actualText = cleanText(actualText)
				task.wait(waitTime)
				DialogueManager.ShowText_ForDuration(actualText, duration)
			else
				text = cleanText(text)
				task.wait(waitTime)
				DialogueManager.ShowText_Forever(text)
			end
		else
			DialogueManager.ShowText_Forever(cleanText(dialogue))
		end
	end
end

function DialogueManager.TickText()
	local accumulatedTime = 0
	local segments = processFormatting(current_text)
	local displayedText = ""

	for _, segment in ipairs(segments) do
		if not looping then break end

		if segment.skip then
			displayedText = displayedText .. segment.text
			dialogueUI.Text = displayedText
			playSound()
			continue
		end

		local i = 1
		while i <= #segment.text do
			if not looping then break end

			local char = segment.text:sub(i, i)

			if char == " " and segments[_ - 1] and segments[_ - 1].skip then
				displayedText = displayedText .. char
				dialogueUI.Text = displayedText
				i = i + 1
				continue
			end

			local pauseTime, skipCount, removeChar = calculatePauseDuration(segment.text, i)

			if pauseTime > 0 then
				if not removeChar then
					displayedText = displayedText .. char
					dialogueUI.Text = displayedText
				end
				i = i + skipCount
			else
				displayedText = displayedText .. char
				dialogueUI.Text = displayedText

				if not char:match("[%p%s]") then
					playSound()
				end

				i = i + 1
			end

			local targetDelay = pauseTime > 0 and pauseTime or incrementDelay
			while accumulatedTime < targetDelay do
				accumulatedTime = accumulatedTime + RunService.Heartbeat:Wait()
			end
			accumulatedTime = accumulatedTime - targetDelay
		end
	end

	looping = false
end

return DialogueManager
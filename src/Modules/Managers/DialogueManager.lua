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

local CharMap = {}
CharMap.__index = CharMap

function CharMap.from(text: string)
	local characters = {}
	for i = 1, #text do
		characters[i] = {
			char = text:sub(i,i),
			state = "pending", -- pending/fading/visible
			progress = 0,
			startTime = nil
		}
	end
end

function CharMap.ParseFormattedText(text)
	local parsedText = {}
	local index = 1
	local length = #text
	local currentSpeed = nil -- Default speed (nil means it follows the typewriter's default)

	while index <= length do
		local char = text:sub(index, index)

		-- Handle Comma Pause (",")
		if char == "," then
			table.insert(parsedText, {char = char, pause = 0.3})

			-- Handle Period Pause (".")
		elseif char == "." then
			table.insert(parsedText, {char = char, pause = 0.5})

			-- Handle 1-Second Pause ("|")
		elseif char == "|" then
			if text:sub(index + 1, index + 1) == "|" then
				-- Skip, prevent multiple '||' being misread
				index = index + 1
			else
				table.insert(parsedText, {char = "", pause = 1}) -- No character, just pause
			end

			-- Handle Custom Pause ("|n|")
		elseif char == "|" and text:sub(index + 1, index + 1):match("%d") then
			local delayStr = ""
			index = index + 1 -- Move past "|"

			while index <= length and text:sub(index, index):match("%d") do
				delayStr = delayStr .. text:sub(index, index)
				index = index + 1
			end

			if text:sub(index, index) == "|" then
				table.insert(parsedText, {char = "", pause = tonumber(delayStr) or 1})
			end

			-- Handle Instant Display ("_text_")
		elseif char == "_" then
			local instantText = ""
			index = index + 1

			while index <= length and text:sub(index, index) ~= "_" do
				instantText = instantText .. text:sub(index, index)
				index = index + 1
			end

			table.insert(parsedText, {char = instantText, pause = 0, instant = true})

			-- Handle Speed Change ("[speed=n]")
		elseif char == "[" and text:sub(index + 1, index + 6) == "speed=" then
			local speedStr = ""
			index = index + 7 -- Move past "[speed="

			while index <= length and text:sub(index, index):match("%d") do
				speedStr = speedStr .. text:sub(index, index)
				index = index + 1
			end

			if text:sub(index, index) == "]" then
				currentSpeed = tonumber(speedStr) or nil -- Update speed
			end

			-- Normal Character
		else
			table.insert(parsedText, {char = char, pause = 0, speed = currentSpeed})
		end

		index = index + 1
	end

	return parsedText
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

	local startTime = os.clock()
	local lastCharTime = 0
	local nextCharIndex = 1

	while true do
		local currentTime = os.clock() - startTime
		local needsUpdate = false

		-- Add new characters when it's their turn
		while nextCharIndex <= #characters and currentTime >= lastCharTime + charDelay do
			characters[nextCharIndex].state = "fading"
			characters[nextCharIndex].startTime = os.clock()
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
				char.progress = math.min(1, (os.clock() - char.startTime)/fadeTime)

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
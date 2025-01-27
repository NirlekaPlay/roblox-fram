--[[
		// FileName: DialogueManager.lua
		// Written by: NirlekaDev | Mike

				CLIENT ONLY.
]]

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require

local ssp2d = require("SoundStreamPlayer2D")

local ui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Dialogue").root
local speaker_click = ssp2d.new(SoundService.Isolated.dialogue)
local dialogueUI = ui.dialogue_backdropUI.text
local dialogueUI_backdrop = ui.dialogue_backdropUI
local dialogueSpeed = 1
local incrementDelay = 0.05
local current_text = ""

local looping = false

local DialogueManager = {}

function DialogueManager.ShowText_ForDuration(activeText : string, showDuration : number)
	looping = false
	DialogueManager.ShowDialogue()
	dialogueUI.Text = activeText
	current_text = activeText
	looping = true
	DialogueManager.TickText()
	task.wait(showDuration)
	DialogueManager.HideDialogue()
end

function DialogueManager.ShowText_Forever(activeText : string)
	looping = false
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
	dialogueUI.Visible = true
	dialogueUI_backdrop.Visible = true
end

function DialogueManager.TickText()
	local accumulatedTime = 0
	local targetDelay = incrementDelay
	local textLength = string.len(current_text)

	for i = 1, textLength do
		if looping then
			dialogueUI.Text = string.sub(current_text, 1, i)

			speaker_click.pitch_scale = math.random(0.2, 0.6)
			speaker_click:Play()

			while accumulatedTime < targetDelay do
				accumulatedTime = accumulatedTime + RunService.Heartbeat:Wait()
			end

			accumulatedTime = accumulatedTime - targetDelay
		else
			break
		end
	end

	looping = false
end

return DialogueManager
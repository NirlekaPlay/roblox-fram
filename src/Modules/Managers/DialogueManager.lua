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

local ssp2d = require("SoundStreamPlayer2D")
local randf_range = require("math").randf_range

local ui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Dialogue").root
local ui_dialogue_text = ui.dialogue_backdropUI.text
local ui_dialogue_backdrop = ui.dialogue_backdropUI
local speaker_click = ssp2d.new(SoundService.Isolated.dialogue)

local DialogueManager = {}

function DialogueManager.HideDialogue()

end

function DialogueManager.ShowDialogue()
end

return DialogueManager
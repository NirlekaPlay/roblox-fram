local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local sceneMan = require("SceneManager")
local buttonClass = require("ButtonClass")
local dia = require("DialogueManager")
local cam = require("CameraManager")
local chap = require("ChapterTextManager")
local cursor = require("CursorManager")
local ssp2d = require("SoundStreamPlayer2D")

local ambience = ssp2d.new(game.SoundService.Ambience.NoiseAmbience)
ambience.sound.Looped = true

local doorButton
local t = {}

function t._ready()
	if not sceneMan:IsManagerReady() then
		sceneMan.Ready:Wait()
	end
	if not sceneMan:IsSceneLoaded() then
		sceneMan.LoadScene("Baseplate"):Wait()
	end
	task.wait(.3)
	cam.SetSocket("sky")
	ambience:Play()
	doorButton = buttonClass.new(workspace.Scenes:WaitForChild("Baseplate").WorldRoot.Door.Door)
	doorButton.isActive = false
	t.BeginFirstSequence()
end

function t.BeginFirstSequence()
	dia.PlaySequence([[
		\n5 ...
		\n1 Oh!| Hello there!
		\n1.13 Uhm.. can you move?
		\n1 Or.. I dont't know..
		@1.5 look around?]]
	)
	dia.PlaySequence([[
		\n2 Oh...
		\n2 @1 Hang on let me fix that..
	]])
	chap.BeginShowChapter(1, "Unwanted Guest", 5)
	cursor.SetCursor(true, true)
	cursor.SetCursorLock(false)
	cam.SetTiltCamera(true)
	dia.PlaySequence(
		"\n2 There you go!| \n2 @2 Try looking around!|"
	)
	task.wait(3)
	chap.BeginShowChapter(69, "THATS IT. (fuck off)", 5)
	--[=[dia.PlaySequence(
		[[\n6 You're..
		\n.3 You're still on the ground..
		\n2.3 Oh no.. I haven't programmed it!
		\n2 I NEED TO DO IT.
		\n1.5 @2.5 _EVERY_ | _SINGLE_ | _TIME!_|
		]]
	)
	]=]
end

return t
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local sceneMan = require("SceneManager")
local dia = require("DialogueManager")
local cam = require("CameraManager")
local cursor = require("CursorManager")
local ssp2d = require("SoundStreamPlayer2D")

local ambience = ssp2d.new(game.SoundService.Ambience.NoiseAmbience)
ambience.sound.Looped = true
local t = {}

function t._ready()
	if not sceneMan:IsManagerReady() then
		sceneMan.Ready:Wait()
	end
	sceneMan.LoadScene("Baseplate"):Wait()
	task.wait(.3)
	cam.SetSocket("sky")
	ambience:Play()


	dia.PlaySequence(
		"\n5 ... \n2 Oh!| Hello there! \n2 Uhm.. can you move? \n1 Or.. I dont't know.. \n.3 look around? \n2 Oh... \n1 @1 Hang on let me fix that.."
	)
	task.wait(5)
	cursor.SetCursor(true, true)
	cursor.SetCursorLock(false)
	cam.SetTiltCamera(true)

	dia.PlaySequence(
		"\n2 There you go!| \n2 @2 Try looking around!|"
	)
	dia.PlaySequence(
		[[\n6 You're..
		\n.3 You're still on the ground..
		\n2.3 Oh no.. I haven't programmed it!
		\n2 I NEED TO DO IT.
		\n1.5 @2.5 _EVERY_ | _SINGLE_ | _TIME!_|
		]]
	)
end

return t
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local sceneMan = require("SceneManager")
local buttonClass = require("ButtonClass")
local dia = require("DialogueManager")
local cam = require("CameraManager")
local chap = require("ChapterTextManager")
local cursor = require("CursorManager")
local effectsMan = require("EffectsManager")
local ssp2d = require("SoundStreamPlayer2D")
local hsd = require("HeadShakeDetector")
local skyMan = require("SkyManager")
local maid = require("Maid").new()

local lightShutOn = ssp2d.new(game.SoundService.Isolated.light_on)

local t = {}

function t.BeginFirstSequence()
	sceneMan.LoadScene("Basement"):Wait()
	skyMan.SetTimeOfDay("midnight")
	chap.BeginShowChapter(2, "IN THE DARK", 5)
	cam.SetSocket("main")
	lightShutOn:Play()
	effectsMan.PlayAnimationAlias("LightShutOn")
	task.wait(10)

	dia.PlaySequence([[
			\n.1 Wait...
			\n.5 Am I being too harsh on you?
			\n1 Maybe you were just moving around your head,
			\n.1 And I took that as a no?
			\n1 ...
			\n.5 Alright then..
			\n.5 One last chance.
			\n1 Did you mean yes, or no?
	]])

	hsd.SetDetection(true)
	maid:GiveTask(hsd.OnNod:Connect(function()
		maid:DoCleaning()
		--hsd.SetDetection(false)
	end))
	maid:GiveTask(hsd.OnShake:Connect(function()
		maid:DoCleaning()
		hsd.SetDetection(false)

		dia.PlaySequence([[
			\n.1 Aha.
			\n.5 So you _DID_ mean it?!
			\n.7 I'm disappointed in you..
			\n1 Alright then. You stay here.
			\n.7 Thankfully theres a lil' target stand to keep you company.
			\n1 And for the last time..
			\n.5 @1 Cya.
		]])
	end))
end

return t
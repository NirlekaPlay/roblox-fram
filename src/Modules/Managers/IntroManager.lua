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
local basementManager = require("BasementManager")
local maid = require("Maid")
local maid_main = maid.new()

local speakers = {
	ambience = ssp2d.new(game.SoundService.Ambience.NoiseAmbience),
	lightShutOff = ssp2d.new(game.SoundService.Isolated.light_shut),
	music_relax = ssp2d.new(game.SoundService.Music.music_relax)
}

local world_objects = {
	button_door = nil
}

local t = {}

function t._ready()
	maid_main.GiveTasksArray({
		speakers,
		world_objects
	})
	if not sceneMan:IsManagerReady() then
		sceneMan.Ready:Wait()
	end
	if not sceneMan:IsSceneLoaded() then
		sceneMan.LoadScene("Baseplate"):Wait()
	end
	task.wait(.3)
	cam.SetSocket("sky")
	speakers.ambience:Play()
	world_objects.door_button = buttonClass.new(workspace.Scenes:WaitForChild("Baseplate").WorldRoot.Door.Door)
	world_objects.door_button.isActive = false
	task.spawn(t.BeginFirstSequence)
end

function t.BeginFirstSequence()
	dia.PlaySequence([[
		\n5 ...
		\n1 @1 Oh!| Hello there!
		\n1.13 Uhm.. can you move?
		\n1 Or.. I don't know..
		@1 look around?]]
	)
	dia.PlaySequence([[
		\n2 Oh...
		\n.5 @1 Hang on, let me fix that..
	]])
	chap.BeginShowChapter(1, "Unwanted Guest", 5)
	cursor.SetCursor(true, true)
	cursor.SetCursorLock(false)
	cam.SetTiltCamera(true)
	dia.PlaySequence([[
		\n2 There you go!
		\n2 @1.5 Go!| Look around!
	]])
	dia.PlaySequence([[
		\n6 Yeah you can't really see anything...
		\n1.2 You can't even stand up or walk..
		\n1.3 But I have so much to show to you..
		\n1.3 @1 Administrator.
	]])
	dia.PlaySequence([[
		\n3 Alright...
		\n1 Here's the deal.
		\n1 You're gonna wait here|
		\n1.5 and wait for me to fix things..
		\n1.3 So that you can stand up and walk.
		\n1.3 And whatever you do...
		\n1 _DO_ | _NOT_ | _OPEN_ | _THE_ | _DOOR._ |
		\n1.5 Got it?
		\n2.2 ...
		\n1 I'm being serious.
		\n1 Nod if you understood me.
	]])
	local maid_detection = maid.new()
	hsd.SetDetection(true)
	maid_detection:GiveTask(hsd.OnNod:Connect(function()
		maid_detection:DoCleaning()
		hsd.SetDetection(false)
		dia.PlaySequence([[
			\n.3 ...
			\n2 Did you actually just nod at me?
			\n1 Is that a yes?
			\n1.3 ...
			\n1.3 Alright then.| Deal!
			\n1 No opening doors, you got it.
			\n1 @1 (Man.. I actually like this one..)
		]])
		effectsMan.PlayAnimationAlias("FadeOut")
		speakers.ambience:Stop()
		speakers.music_relax:Play()
		chap.BeginShowChapter(2, "COMING SOON...", 5)
	end))
	maid_detection:GiveTask(hsd.OnShake:Connect(function()
		maid_detection:DoCleaning()
		hsd.SetDetection(false)
		dia.PlaySequence([[
			\n.1 Wha-
			\n.5 Did you just shake your head?!
			\n1 No?!
			\n1 Yeah. You're not a very fitting subject.
			\n1 Are you?
			\n2 Just to keep things safe..
			\n1.5 @1 I'll send you back to the shadow realm.
		]])
		speakers.ambience:Stop()
		speakers.lightShutOff:Play()
		effectsMan.PlayAnimationAlias("LightShutOff")
		task.wait(1)
		dia.ShowText_ForDuration("Cya!", 1)
		basementManager.BeginFirstSequence()
		t.Cleanup()
	end))
end

function t.Cleanup()
	maid_main:DoCleaning()
end

return t
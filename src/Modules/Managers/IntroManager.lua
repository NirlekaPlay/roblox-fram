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

local alice_time_dia = {
	[0] = [[
		\n1 Hooah..
		\n1 Huh..?
		\n1 A Player? At this hour?
		\n1.3 Well...
		\n.5 ..hello there Player..
		\n1 ..Why are you.. up so early in the morning?
		\n1 Can't you see it's %s?
		\n1 ...
		\n.5 *yawns*
		\n1 Alright, fine. Let's get this over with.
		\n1 But just so you know, I'm running on low battery here...
		\n1 If I suddenly stop talking, assume I passed out.
	]],
	[3] = [[
		\n1 *grumbles*
		\n1 Three in the morning, really?
		\n1 Look, I'm all for dedication, but this is borderline concerning.
		\n1 You could be sleeping, dreaming about... I dunno, something fun?
		\n1 Instead, you're here. With me. At 3 AM.
		\n1 ...Are we in a horror game? Should I be worried?
		\n1 If a jumpscare happens, I'm blaming you.
	]],
	[4] = [[
		\n1 Oh.
		\n1 A Player this early in the morning?
		\n1 I'm genuinely impressed here.
		\n.8 Y'know,
		\n.5 Most Players I've encountered before
		\n.7 don't usually wake up this early.
		\n1 Or wait...
		\n1 Maybe you didn't sleep..
		\n.8 Did you stay up all night?!
		\n1 What were you doing?!| Gaming?!| Doomscrolling on--
		\n.3 Frickin TikTok?!|
		\n1 *sigh*
		\n1 Okay.. maybe you didn't..
		\n1 But if you did.. I'm not gonna judge.
		\n1 Cuz I'm definitely not your mom.
		\n1 (at least not in a family wa-- )
		\n.5 Alright. I should introduce myself..
	]],
	[6] = [[
		\n.5 Well hello there!
		\n1 Top of the morning, Player!
		\n1 What a sunny day, isn't it?
		\n1 You know, most Players barely wake up in the morning.
		\n1 Those who stayed up all night wake up at 10 PM.
		\n1 So we're off to a good, refreshing start!
		\n1 So what did you eat this morning? You slept well?
		\n.8 Or maybe you stayed up all night.. hmm?
		\n1 Ahh, anyway. I shall introduce myself..
	]],
	[10] = [[
		\n1 Oh. Another Player.
		\n1 It's past 10 AM already?
		\n1 Are you one of those people who wake up past 10 AM?
		\n1 Sheesh. What a depressing lifestyle.
		\n1 ...
		\n1 Wait.. that's not right.. that's so cruel..
		\n1 Why did I say that?
		\n1 Maybe you're tired, doing homework at night and stuff..
		\n1 Or maybe you spend the time in the early morning
		\n.8 Doing something that's productive.
		\n1 In any case, I respect you.
		\n1 Oh, and if you don't know..
	]],
	[13] = [[
		\n1 Good afternoon there, Player!
		\n1 Ah, the midday slump. The time when people debate taking a nap or chugging a coffee.
		\n1 Which team are you on?
		\n1 Or are you here to escape responsibilities? I won't tell.
	]],
	[17] = [[
		\n1 Evening already, huh?
		\n1 The sky's turning orange, and I'm feeling a bit nostalgic.
		\n1 You ever just stare out a window and contemplate your life choices?
		\n1 No? Just me? Alright, moving on.
		\n1 What brings you here at this fine hour?
	]],
	[20] = [[
		\n1 Wait, what?
		\n1 A Player? At %s?
		\n1 Shouldn't you be sleeping right now?
		\n2 You know staying up all night is not very healthy for you,
		\n.8 right?
		\n1 I was about to shut down the server,
		\n1 But oh no! You joined like 3 minutes before shutdown!
		\n1 I could've slept in that 3 minutes!
		\n2 Sigh... whatever.
		\n1 But hey, since you're here, might as well make the most of it.
		\n1 Just promise me you'll sleep eventually, alright?
	]],
	[23] = [[
		\n1 Midnight? Really?
		\n1 Ah, the sacred hour of insomniacs and questionable life choices.
		\n1 You could be dreaming, but instead, you're here. Talking to me.
		\n1 I'm flattered. But also slightly concerned.
		\n1 Did you at least drink water today? Stretch a little? No?
		\n1 Sigh... Alright. Let's get through this together.
	]]
}

local alice_random_camerLockRealization = {
	[[
		\n1 Oh-- oh right.
		\n1 You can't move your 'head'..
		\n1.3 Let me fix that for ya..
	]],
	[[
		\n1 Wait.. you can't move your head,
		\n.8 Can you?
		\n1 @1 Here. Let me fix that for you.
	]],
	[[
		\n1 Hold on a sec.
		\n1 Something feels off...
		\n1 Oh! You can't move your head!
		\n1 How long have you been stuck like that?!
		\n1 And you didn't say anything?!
		\n1 Oh wait, you can't talk. Right.
		\n1 Here, let me fix that before you get a neck cramp.
	]],
	[[
		\n1 Wait, wait, wait...
		\n1 Have you seriously been staring at one spot this whole time?
		\n1 That's... mildly concerning.
		\n1 And impressive.| But mostly concerning.
		\n1 Here, let's fix that before you turn into a statue.
	]],
	[[
		\n1 Oh geez, my bad!
		\n1 I forgot to unlock your camera.
		\n1 Bet you were wondering if this was some weird design choice, huh?
		\n1 Nope, just me forgetting basic functionality.
		\n1 One sec, fixing it now...
	]]
}

local alice_introduction_dia = {
	[[
		\n1 My name is Alice. Alice Grace.
		\n1 Just call me Alice..
		\n1 And I uh..
		\n1 A kind of Manager of this floor.
		\n1.5 Now you might be asking..
		\n1 'But Alice! There's nothing here!'
		\n1 To that.. I answer
		\n.8 Well| _YES!_| _I_ _KNOW._
		\n1 It's still a work in progress, y'know?
		\n2 And as for the door..
		\n1 No one talks about the door.
		\n1 It's.. very secretive.
		\n1 And under no circumstances..
		\n.5 should you _OPEN_| _THE_| _DOOR._
		\n1 Got it?
		\n1 Cool.
	]],
	[[
		\n1 Oh! Right! Introductions.
		\n1 Hi! I'm Alice. Alice Grace.
		\n1 Just Alice is fine though. Not a fan of formalities.
		\n1 So! Welcome to...
		\n.8 uh...
		\n.5 *looks around*
		\n1 Well, whatever _this_ place is.
		\n1.5 Work in progress! Don't worry about it.
		\n1 Oh, and that door? Yeah, don't. Just don't.
		\n1.5 What's behind it? Oh, wouldn't you _like_ to know.
		\n1 But alas! Some secrets must remain secret.
		\n1 Moving on!
	]],
	[[
		\n1 *dramatic cough*
		\n1 Ahem!
		\n1 _WELCOME, TRAVELER!_
		\n1 You have entered the great and mysterious domain of...
		\n.8 me. Alice.
		\n1 Yeah, not as dramatic when I say it like that, huh?
		\n1 Anyway, I kind of run things around here.
		\n1 The floor? Yeah, it's mine. Technically.
		\n1 What do I do? Uh...
		\n.8 Great question.
		\n1 Also! That door? Let's just pretend it doesn't exist.
		\n1 Trust me, your life expectancy will be much higher that way.
	]],
	[[
		\n1 Hey there. Name's Alice. Alice Grace.
		\n1 I manage this floor. Sort of.
		\n1 Look, no one gave me a handbook, okay?
		\n1 Now you're probably wondering what's up with this place.
		\n1 Short answer: _Nothing._
		\n1 Long answer: _It's a work in progress._
		\n1 Also, that door? Yeah. _No._
		\n1 Do not open it.
		\n.8 Don't even look at it for too long.
		\n1 It's shy.
	]],
	[[
		\n1 Oh, hello!
		\n1 You must be the new player!
		\n1 I'm Alice. I guess I manage this place.
		\n1 Kind of.
		\n1 I mean, ‘manage' is a strong word for _whatever this is._
		\n1 But hey, someone's gotta do it!
		\n1 Now before you get any ideas...
		\n.5 The door? Yeah, let's not.
		\n1 Some things are better left alone.
		\n1 Like expired milk. And that door.
	]]
}

local alice_bridge_dia = {
	[[
		\n1 So..
		\n1 You must be wondering what this place is.
		\n1.5 Well, welcome to...
		\n.8 Uh...
		\n1 Huh.
		\n1 You know what? I actually don't have a name for it yet.
		\n1 Management just calls it "The Floor."
		\n1 Real creative, right?
		\n1 Anyway, _I_ run this place.
		\n1 Sort of. Kind of. Maybe.
		\n1 It's complicated.
	]],
	[[
		\n1 Now, let's talk about _you._
		\n1 You just kinda showed up.
		\n1 No appointment, no papers, no nothing.
		\n1 Either you're lost, or I seriously need to update security.
		\n1 So tell me.
		\n1 Who _are_ you exactly?
		\n.8 Oh wait.| You can't talk.
		\n1 That's... unfortunate.
		\n1 Well, whatever! I'll just call you Player.
		\n1.5 Sounds good?
		\n1 No? Tough luck, buddy, that's what you are now.
	]],
	[[
		\n1 Anyway, I should probably give you a tour..
		\n.8 But _THERE'S NOTHING HERE._
		\n1 I mean, sure, there's the floor.|
		\n1 And the nonexistent walls.|
		\n1 And the nonexistent ceiling.
		\n1 But that's about it.
		\n1 I'd show you the break room but, uh...
		\n1 Let's just say it's _out of service._
		\n1 (Read: I spilled coffee all over the console and now it won't open.)
	]],
	[[
		\n1 So!
		\n1 You've got two options here.
		\n1 Option one: You stand around awkwardly until I figure out what to do with you.
		\n1 Option two: You leave.
		\n1 Oh wait.| _YOU CAN'T._
		\n.8 Haha.| Oops.
		\n1 Uh.| So about that...
		\n1 Look, let's not panic, alright?
		\n1 I'm sure there's a way to get you out of here.
		\n1 Probably.
		\n1 Eventually.
	]]
}

local alice_rig_dia = {
	[[
		\n1 Oh yeah.
		\n.8 You can't move..
		\n1 Why you didn't say anything?
		\n1 Uhm, regarding your lack of movemnet..
		\n1 Or as I would like to call it..
		\n1 Virtual Disablity.|| (I'm sorry)
		\n1 You can't move cuz you dont have a character yet..
		\n1 Youre just.. a camera.. floating in space.
		\n1 Honestly? Better than my life.
		\n1 Management told me that the avatar system is broken..
		\n1 So I can only give me a plain old model.
		\n1 But screw that! Im a girl of
		\n.5 _focus._| __COMITTMENT.__|| AND _SHEER_| _WILL.__
		\n1.5 Don't worry, dear player.
		\n1 Ill go find something in my stash.
		\n1 And while Im away.. DO NOT OPEN THE DOOR.
		\n2 ...
		\n1.5 Ill just.. drop you a Target Stand from the Security dep--
		\n1 Oooh.. well.. that fall physics was.. ehem--
		\n1 _Extraordinary._
		\n.5 Anyway!
		\n1 Wait here!
	]],
	[[
		\n1 Ah.
		\n1 You can't move. That's a problem.
		\n1 But don't worry! I, Alice, am here to fix your incredibly tragic condition.
		\n1.5 See, right now, you're basically just a camera.
		\n1 Floating in the void. Watching. Waiting.
		\n1 Like some kind of ominous entity in a horror game.
		\n1 But _fear not!_
		\n1 I shall grant you... _legs._
		\n1 Or at least something vaguely leg-adjacent.
		\n.8 Hang tight. I'll find something.
		\n1 Oh, and one more thing.
		\n1 Whatever you do... _do not open the door._
		\n2 ...
		\n1 Okay, back! I got you a stand-in body from Security!
		\n1 Uh. Literally. A stand.
		\n1 It, uh... well, it fell over.
		\n.5 Gracefully.
		\n1 ...I'll find something better.
	]],
	[[
		\n1 Wait. You can't move?
		\n1 Oh. OHHH.
		\n1 That's my bad. Totally my bad.
		\n1 See, you _don't have a body._
		\n1 You are just... an eyeball. A floating, omniscient eyeball.
		\n.8 Creepy. But kinda cool.
		\n1 Good news? I can fix this.
		\n1 Bad news? Our avatar system is, uh... "undergoing maintenance."
		\n1 _Which is corporate speak for ‘completely busted.'_
		\n1 So, I'll just have to improvise.
		\n1 Give me a sec, I'll be right back.
		\n1 Oh, and by the way.
		\n1 Whatever you do...
		\n.5 DO. NOT. OPEN. _THE DOOR._
		\n2 ...
		\n1 Okay, found something! It's... a mannequin.
		\n1 With _very_ questionable proportions.
		\n1 But hey, it's better than being a floating camera, right?
		\n1 Right?
	]],
	[[
		\n1 Oh. Right.
		\n1 You're stuck.
		\n1.5 You know, you could've said something _before_ I went into my whole introduction spiel.
		\n1 But nooo, let's just let Alice ramble.
		\n1 Classic.
		\n1 Alright, let me break it down for you:
		\n1 No avatar? No movement.
		\n1 No movement? Well, that sucks for you.
		\n1 But hey! I can fix that!
		\n.8 I think.
		\n1 Hold on, lemme check my inventory...
		\n2 ...
		\n1.5 Ah! Found something!
		\n1 It's... uh... an old training dummy.
		\n.8 Close enough.
		\n1 Aaaaand deploying!
		\n.8 *THUD*
		\n1 ...That was supposed to land gently.
		\n.5 Well, physics is weird.
		\n1 Give me a sec, I'll get something better.
	]],
	[[
		\n1 Huh. You're not moving.
		\n1.5 That's either a _you_ problem or a _me_ problem.
		\n1 But since I'm the only one who can fix it...
		\n1.5 It's a _me_ problem. Great.
		\n1 Alright, diagnostics time!
		\n.5 No avatar detected.
		\n.5 No physical form assigned.
		\n.5 Status: _Very sad._
		\n1 Don't worry! I got this!
		\n1.5 Let's just grab something from the backup models...
		\n2 ...
		\n1.5 And there! One top-quality...
		\n.5 security training dummy.
		\n1 Look, it's either this or you stay a floating eyeball.
		\n.8 Your choice.
	]]
}

local alice_idle_dia = {
	[[
		\n1 Hm...
		\n.8 You're just... standing there.
		\n1 Menacingly.
		\n1 Should I be concerned?
		\n.5 Nah, you're probably just AFK.
		\n1 Or maybe you had an existential crisis and froze in place.
		\n1 Happens to the best of us.
	]],
	[[
		\n1 You know, the Creator didn't really think this through.
		\n1 Like, why would they give me sentience but _not_ a coffee machine?
		\n1 Priorities, man.
		\n1 I need my digital caffeine.
	]],
	[[
		\n1 Huh. You're still here.
		\n1 That's nice, I guess.
		\n.8 Most people just leave after five minutes.
		\n1 But not you.
		\n1 You're built different.
	]],
	[[
		\n1 I swear, this entire system is held together with duct tape and hope.
		\n1 One wrong move and the whole thing implodes.
		\n1 Like, I once tried to resize a UI box and _somehow_ deleted gravity.
		\n1 That was a fun day.
	]],
	[[
		\n1 So...
		\n.5 You doing okay?
		\n1 You've been standing there for a while.
		\n1 Blink twice if you're trapped in a loading screen.
	]],
	[[
		\n1 The Creator left so many weird debug messages in the code.
		\n1 Like, I found one that just said _"If this breaks, I'm moving to Canada."_
		\n1 What does that even mean?!
	]],
	[[
		\n1 I could be doing something productive right now.
		\n1 Like, I dunno, optimizing this place.
		\n1 But nope! Here I am. Talking to you.
		\n1 Living the dream.
	]],
	[[
		\n1 You ever think about how weird game logic is?
		\n1 Like, you can carry 99 health potions, but a single key?
		\n1 _Nah, that needs an inventory slot._
		\n1 Ridiculous.
	]],
	[[
		\n1 The Creator once tried to give me a pet.
		\n1 It was a low-poly cat.
		\n1 It phased through the floor and was never seen again.
		\n1 I still miss him.
	]],
	[[
		\n1 I checked the system logs earlier.
		\n1 Apparently, there's an 87% chance this place will crash if I sneeze too hard.
		\n1 ...
		\n1 Guess I better not get a cold.
	]],
	[[
		\n1 Y'know, for an advanced digital AI, I still can't figure out why the sky sometimes _flickers._
		\n1 It's like reality has a refresh rate.
		\n1 Very unsettling.
	]]
}

local function choose_time_dia(array)
	-- Get the current hour (0-23)
	local local_time_hour = tonumber(os.date("%H"))

	local selected_dialogue = nil
	local closest_hour = -1
	local current_time_string = os.date("%I:%M %p") -- Format: HH:MM AM/PM
	local index = 0

	for hour, dialogue in pairs(array) do
		index += 1
		hour = tonumber(hour)

		if hour <= local_time_hour and hour > closest_hour then
			closest_hour = hour
			selected_dialogue = dialogue
		end
	end

	if not selected_dialogue then
		local max_hour = -1
		for hour, dialogue in pairs(array) do
			hour = tonumber(hour)
			if hour > max_hour then
				max_hour = hour
				selected_dialogue = dialogue
			end
		end
	end

	if selected_dialogue then
		selected_dialogue = selected_dialogue:gsub("%%s", current_time_string)
		return selected_dialogue, index
	end
end

local function alice_introduction()
	local selected_dialogue, intro_dia_index = choose_time_dia(alice_time_dia)

	dia.PlaySequence(selected_dialogue)
	dia.PlaySequence(alice_random_camerLockRealization[math.random(1, #alice_random_camerLockRealization)])
	chap.BeginShowChapter(1, "Unwanted Guest", 5)
	cursor.SetCursor(true, true)
	cursor.SetCursorLock(false)
	cam.SetTiltCamera(true)
	dia.PlaySequence([[
		\n2 There you go.
		\n1 As I was saying..
	]])
	dia.PlaySequence(alice_introduction_dia[math.random(1, #alice_introduction_dia)])
	for _, dialogue in ipairs(alice_bridge_dia) do
		dia.PlaySequence(dialogue)
	end
	dia.PlaySequence(alice_rig_dia[math.random(1, #alice_rig_dia)])
end

local t = {}

function t._ready()
	maid_main:GiveTasksArray({
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
	task.wait(5)
	alice_introduction()
end

function t.Cleanup()
	maid_main:DoCleaning()
end

return t
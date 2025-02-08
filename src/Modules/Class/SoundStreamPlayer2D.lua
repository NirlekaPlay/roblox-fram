-- SoundStreamPlayer2D.lua
-- NirlekaDev
-- January 26, 2024

--[[
	A kind of port from Godot's AudioStreamPlayer, both 2D and 3D.

	Constructor looks like a mess?
	Well blame whoever thought that not adding metamethod for detecting table changes was a good idea.
]]

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Maid = require("Maid")
local Inst = require("inst")

local function strictTypeSet(self, i, v)
	local currentValue = self[i]
	if not currentValue then
		error(string.format("Attempt to set SoundPlayer::%s (not a valid member)\n\n", tostring(i)))
	end

	if typeof(v) ~= typeof(currentValue) then
		error(string.format("Attempt to set SoundPlayer[%s] = %s (not a valid type)\n\n", tostring(i), tostring(v)))
	end

	if typeof(v) == "Instance" and v.ClassName ~= currentValue.ClassName then
		error(string.format("Attempt to set SoundPlayer[%s] = %s (wrong Instance type)\n\n", tostring(i), tostring(v)))
	end

	rawset(self, i, v)
end

local function setSoundInstance(sound)
	assert(typeof(sound) == ("Instance" or "string"),
		"sound must be either of type string or Instance. Got %s \n\n %s",
		typeof(sound),
		debug.traceback()
	)

	if type(sound) == "string" then
		return Inst.create("Sound", nil, game.SoundService, {SoundId = sound})
	else
		return sound
	end
end

local function setSoundGroup(sound)
	assert(typeof(sound) == ("Instance" or "string"),
		"sound must be either of type string or Instance. Got %s \n\n %s",
		typeof(sound),
		debug.traceback()
	)

	if not sound.SoundGroup then
		sound.SoundGroup = SoundService.World
		sound.Parent = SoundService.World
		return SoundService.World
	else
		return sound.SoundGroup
	end
end

local SoundPlayer = {}
SoundPlayer.__index = SoundPlayer

--[=[
	Constructs a new SoundStreamPlayer2D object

	```lua
	local ssp2d = SoundStreamPlayer2D.new("rbxassetid://1283290053", {pitch_scale = 2})
	```

	@param sound string | Sound
	@param properties {[string]:any}
	@return SoundStreamPlayer2D
]=]
function SoundPlayer.new(sound: string | Sound, properties: {[string]: any}?)
	local data = {
		autoplay = false,
		deffered_playing = false,
		sound = setSoundInstance(sound),
		sound_group = setSoundGroup(sound),
		pitch_scale = 0,
		playing = false,
		play_paused = false,
		volume_db = 1,
		last_time_pos = 0,
		_pitch_sfx = Inst.create("PitchShiftSoundEffect", nil, nil, {Octave = 0}),
		_maid = Maid.new()
	}

	local self = {}

	local mt = {
		__index = function(t, k)
			return SoundPlayer[k] or data[k]
		end,

		__newindex = function(t, k, v)
			--strictTypeSet(t, k, v)
			if data[k] ~= v then
				rawset(data, k, v)

				if k == "playing" or k == "play_paused" then
					if v then
						t:Play(t.last_time_pos)
					else
						rawset(data, "play_paused", true)
						if data.playing then
							t:Stop()
						end
					end
				elseif k == "pitch_scale" then
					data._pitch_sfx.Octave = v
				end
			end
		end
	}

	setmetatable(self, mt)

	data._pitch_sfx.Parent = data.sound
	data._maid:GiveTask(data.sound)
	data._maid:GiveTask(data._pitch_sfx)
	data._maid:GiveTask(data.sound.Stopped:Connect(function()
		rawset(data, "playing", false)  -- Prevent recursion here too
	end))

	if self.autoplay then
		self:Play()
	end

	return self
end

--[=[
	Returns the current time position on the Sound instance.

	```lua
	ssp2d:Play()
	print(ssp2d:GetTimePosition()) --> 0.25
	```

	@return TimePosition number
]=]
function SoundPlayer:GetTimePosition()
	return self.sound.TimePosition
end

--[=[
	Loads the Sound asset so it can be played.
	Returns true if the fetch is successfull.
	Recommended for internal use only.

	@return success boolean
]=]
function SoundPlayer:Preload()
	if self.sound.IsLoaded then
		return true
	end

	local success = false
	ContentProvider:PreloadAsync({self.sound}, function(_, status)
		success = (status == Enum.AssetFetchStatus.Success)
	end)

	if success then
		self.sound.Loaded:Wait()
		return true
	end

	return success
end

--[=[
	Plays the sound.
	Acts as a dispatcher. If deffered playing is
	true, then it will call the :PlayDeffered() method.
	:PlayNormal() if it's not.

	```lua
	ssp2d:Play()
	```

	Note that the arguements will be passed to the functions too.
]=]
function SoundPlayer:Play(...)
	if self.play_deffered then
		self:PlayDeffered()
	else
		self:PlayNormal(...)
	end
end

--[=[
	Plays the sound normally.
	If the sound is already playing, it will
	stop the sound and plays it at the given time position.

	```lua
	ssp2d:PlayNormal()
	```

	@param timePosition number
]=]
function SoundPlayer:PlayNormal(timePosition: number)
	timePosition = timePosition or 0
	local sound: Sound = self.sound

	if self.playing then
		self:Stop()
	end

	if timePosition > sound.TimeLength then
		return
	end
	self.play_paused = false
	sound.TimePosition = timePosition

	local preloadSuccess = self:Preload()
	if preloadSuccess then
		self.playing = true
		sound:Play()
	end
end

--[=[
	Preloads the sound and skips the elapsed preloading time
	when playing.
	If the elapsed time for the preload is longer then the
	sound's time length, it will not play anything.

	```lua
	ssp2d:PlayDeffered()
	```
]=]
function SoundPlayer:PlayDeffered()
	local startTime = tick()
	local preloadSuccess = self:Preload()
	if preloadSuccess then
		local elapsed = tick() - startTime
		if elapsed > self.sound.TimeLength then
			return
		end

		self:Play(elapsed)
	end
end

--[=[
	Stops the sound from playing.
	If you set the .playing to false while playing,
	it will save the time position when it stopped.
	Allowing you to play from the time position it stopped.

	```lua
	ssp2d:Stop()
	ssp2d:Play() -- will play from the beginning

	ssp2d.playing = false
	ssp2d:Play() -- resumes playing from when it was stopped.
	```
]=]
function SoundPlayer:Stop()
	if self.playing then
		if self.play_paused then
			self.last_time_pos = self.sound.TimePosition
		else
			self.last_time_pos = 0
		end
		self.sound:Stop()
	end
end

--[=[
	Deletes the object.
	Any playing sound instance will be stopped
	and destroyed.

	```lua
	ssp2d:Destroy()
	print(ssp2d) -- nil
	```
]=]
function SoundPlayer:Destroy()
	if self.playing then
		self:Stop()
	end
	self._maid:DoCleaning()
	setmetatable(self, nil)
end

return SoundPlayer
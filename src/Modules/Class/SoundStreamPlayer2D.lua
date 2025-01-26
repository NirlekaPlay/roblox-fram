-- SoundStreamPlayer2D.lua
-- NirlekaDev
-- January 26, 2024

--[[
	A kind of port from Godot's AudioStreamPlayer, both 2D and 3D.
]]

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Maid = require("Maid")

export type SoundPlayer2D = {
	autoplay: boolean,
	deffered_playing: boolean,
	sound: Sound,
	soundGroup: SoundGroup,
	pitch_scale: number,
	playing: boolean,
	play_paused: boolean,
	volume_db: number
}

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
function SoundPlayer.new(sound: string | Sound, properties: {[string]:any}?)
	local self = setmetatable({}, SoundPlayer)

	self.autoplay = false
	self.deffered_playing = false
	self.sound = nil
	self.sound_group = nil
	self.pitch_scale = 1
	self.playing = false
	self.play_paused = false
	self.volume_db = 1
	self.last_time_pos = 0

	self._maid = Maid.new()

	if typeof(sound) == "Instance" then
		self.sound = sound
		if not sound.SoundGroup then
			sound.SoundGroup = SoundService.World
			self.sound_group = SoundService.World
		else
			self.sound_group = sound.SoundGroup
		end
	elseif type(sound) == "string" then
		self.sound = Instance.new("Sound")
		self.sound.SoundId = sound
		self.sound_group = SoundService.Isolated
		self.sound.Parent = SoundService.Isolated
	end

	if properties then
		for i, v in pairs(properties) do
			strictTypeSet(self, i, v)
		end
	end

	self._maid:GiveTask(self.sound)
	self._maid:GiveTask(sound.Stopped:Connect(function()
		self.playing = false
	end))

	if self.autoplay then
		self:Play()
	end

	self.__newindex = function(_, i, v)
		strictTypeSet(self, i, v)
		if i == "playing" or "play_paused" then
			if i then
				self:Play(self.last_time_pos)
			else
				self.play_paused = true
				if self.playing then
					self:Stop()
				end
			end
		end
	end

	return self :: SoundPlayer2D
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
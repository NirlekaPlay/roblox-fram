-- SoundPlayer2D.lua
-- NirlekaDev
-- January 22, 2024

local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Promise = require("Promise")
local Maid = require("Maid")
local Signal = require("Signal")

export type SoundState = {
	isPlaying: boolean,
	isLoaded: boolean,
	volume: number,
	position: number,
	length: number
}

export type SoundConfig = {
	autoPlay: boolean?,
	volume: number?,
	destroyOnFinished: boolean?,
	parent: Instance?
}

local SoundPlayer = {}
SoundPlayer.__index = SoundPlayer

function SoundPlayer.new(soundId: string, config: SoundConfig?)
	assert(typeof(soundId) == "string", "SoundId must be a string")

	local self = setmetatable({}, SoundPlayer)

	self._maid = Maid.new()
	self._soundId = soundId
	self._config = config or {}
	self._state = {
		isPlaying = false,
		isLoaded = false,
		volume = self._config.volume or 1,
		position = 0,
		length = 0
	}

	-- Create our events
	self._events = {
		loaded = Signal.new(),
		started = Signal.new(),
		stopped = Signal.new(),
		finished = Signal.new(),
		stateChanged = Signal.new()
	}

	for name, event in pairs(self._events) do
		self._maid:GiveTask(event)
		self[name:sub(1, 1):upper() .. name:sub(2)] = event
	end

	self._sound = Instance.new("Sound")
	self._sound.Volume = self._state.volume
	self._maid:GiveTask(self._sound)

	if self._config.autoPlay then
		self:Preload():andThen(function()
			self:Play()
		end)
	end

	return self
end

function SoundPlayer:Preload()
	if self._loadPromise then
		return self._loadPromise
	end

	self._loadPromise = Promise.new(function(resolve, reject)
		-- Preload the sound
		ContentProvider:PreloadAsync({self._soundId}, function(asset, status)
			if status == Enum.AssetFetchStatus.Success then
				self._sound.SoundId = self._soundId

				-- Wait for sound to load
				local connection
				connection = self._sound.Loaded:Connect(function()
					connection:Disconnect()
					self._state.isLoaded = true
					self._state.length = self._sound.TimeLength
					self._events.loaded:Fire()
					self:_updateState()
					resolve()
				end)
			else
				reject("Failed to load sound: " .. tostring(status))
			end
		end)
	end)

	return self._loadPromise
end

function SoundPlayer:Play()
	return self:Preload():andThen(function()
		if not self._state.isPlaying then
			self._sound.Parent = self._config.parent or workspace
			self._sound:Play()
			self._state.isPlaying = true

			-- Set up monitoring of sound position
			self._maid:GiveTask(RunService.Heartbeat:Connect(function()
				self._state.position = self._sound.TimePosition
				self:_updateState()
			end))

			-- Handle completion
			self._maid:GiveTask(self._sound.Ended:Connect(function()
				self._state.isPlaying = false
				self._events.finished:Fire()
				self:_updateState()

				if self._config.destroyOnFinished then
					self:Destroy()
				end
			end))

			self._events.started:Fire()
			self:_updateState()
		end
	end)
end

function SoundPlayer:Stop()
	if self._state.isPlaying then
		self._sound:Stop()
		self._state.isPlaying = false
		self._events.stopped:Fire()
		self:_updateState()
	end
end

function SoundPlayer:SetVolume(volume: number)
	assert(typeof(volume) == "number" and volume >= 0 and volume <= 1, "Volume must be between 0 and 1")
	self._state.volume = volume
	self._sound.Volume = volume
	self:_updateState()
end

function SoundPlayer:GetState(): SoundState
	return table.clone(self._state)
end

function SoundPlayer:_updateState()
	self._events.stateChanged:Fire(self:GetState())
end

function SoundPlayer:Destroy()
	self._maid:Destroy()
	setmetatable(self, nil)
end

return SoundPlayer
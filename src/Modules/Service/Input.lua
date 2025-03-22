-- Input.lua
-- NirlekaDev
-- January 2, 2024

--[=[
	@class Input

	A singleton class to manage all user inputs.
	Based on Godot's Input class.

	TODO: Gamepad support, mobile support, VR support.
]=]

local UserInputService = game:GetService("UserInputService")

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Array = require("Array")
local InputMap = require("InputMap")
local Maid = require("Maid")
local Signal = require("Signal")

local keys_pressed = Array.new()
local inputs_pressed_events = Array.new()
local inputs_changed_events = Array.new()
local inputs_released_events = Array.new()
local mouse_button_mask = Array.new()
local disabled_input: boolean = false

local velocity_track

local VelocityTrack = {} do
	VelocityTrack.__index = VelocityTrack

	function VelocityTrack.new()
		local self = setmetatable({}, VelocityTrack)

		self.min_ref_frame = 0.1
		self.max_ref_frame = 3.0
		self.velocity = Vector2.zero
		self.screen_velocity = Vector2.zero
		self.accum = Vector2.zero
		self.screen_accum = Vector2.zero
		self.accum_t = 0
		self.last_tick = tick()

		return self
	end

	function VelocityTrack:update(delta_p: Vector2, screen_delta_p: Vector2)
		local currentTick = tick()
		local delta_t = currentTick - self.last_tick
		self.last_tick = currentTick

		if (delta_t > self.max_ref_frame) then
			-- First movement in a long time, reset.
			self.velocity = Vector2.zero
			self.screen_velocity = Vector2.zero
			self.accum = delta_p
			self.screen_accum = screen_delta_p
			self.accum_t = 0
			return
		end

		self.accum += delta_p
		self.screen_accum += screen_delta_p
		self.accum_t += delta_t

		if (self.accum_t < self.min_ref_frame) then
			-- Not enough time has passed to calculate velocity accurately.
			return
		end

		self.velocity = self.accum / self.accum_t
		self.screen_velocity = self.screen_accum / self.accum_t
		self.accum = Vector2.zero
		self.screen_accum = Vector2.zero
		self.accum_t = 0
	end

	function VelocityTrack:reset()
		self.last_tick = tick()
		self.velocity = Vector2.zero
		self.screen_velocity = Vector2.zero
		self.accum = Vector2.zero
		self.screen_accum = Vector2.zero
		self.accum_t = 0
	end
end

local function newInputSignal(input, array)
	if typeof(input) ~= "EnumItem" then
		return
	end

	local event = array[input]
	if not event then
		local signal = Signal.new()
		array[input] = signal
		return signal
	end
end

local Input = {}

function Input._ready()
	UserInputService.InputBegan:Connect(Input._parse_input_began)
	UserInputService.InputChanged:Connect(Input._parse_input_began)
	UserInputService.InputEnded:Connect(Input._parse_input_began)

	velocity_track = VelocityTrack.new()
end

function Input._run(dt)
	local mouse_delta = UserInputService:GetMouseDelta()
	velocity_track:update(mouse_delta, mouse_delta)
end

function Input._parse_input_began(inputObject: InputObject, gameProcessedEvent: boolean)
	if disabled_input then
		return
	end

	if inputObject.KeyCode ~= Enum.KeyCode.Unknown then
		if inputObject.UserInputType == Enum.UserInputType.Keyboard then
			keys_pressed:Insert(inputObject.KeyCode)
		end
	end

	local event = inputs_pressed_events[inputObject]
	if inputs_pressed_events[inputObject] then
		event:Fire()
	end
end

--[=[
	Simulate the press of an action.

	@param actionName string
]=]
function Input.ActionPress(actionName: string)
end

--[=[
	Simulate the release of an action.

	@param actionName string
]=]
function Input.ActionRelease(actionName: string)
end

--[=[
	Gets the last known mouse screen velocity.
	Mouse velocity is only calculated every 0.1 seconds.
]=]
function Input.GetLastMouseScreenVelocity()
	return VelocityTrack.velocity
end

function Input.IsActionPressed(actionName: string)
	if Input.IsAnythingPressed() then
		return false
	end

	local action = InputMap.GetAction(actionName)
	if not action then
		return
	end

	for _, button in ipairs(action.inputs) do
		if type(button) == "table" then
			if Input.IsKeyCombinationPressed(button) then
				return true
			end
		end

		if Input.IsKeyPressed(button) then
			return true
		end
	end

	return false
end

--[=[
	Returns true if any keys are pressed.
]=]
function Input.IsAnythingPressed()
	if disabled_input then
		return false
	end

	if keys_pressed:IsEmpty() and mouse_button_mask:IsEmpty() then
		return false
	end

	return true
end

--[=[
	Returns true if any actions beside the mouse are pressed.
]=]
function Input.IsAnythingExceptMouseArePressed()
	if disabled_input then
		return false
	end

	if keys_pressed:IsEmpty() then
		return false
	end
end

function Input.IsInputEnabled()
	return disabled_input
end

function Input.IsKeyPressed(key: Enum.KeyCode)
	if disabled_input then
		return
	end

	return keys_pressed:Has(key)
end

function Input.IsKeyCombinationPressed(keys: {Enum.KeyCode})
	if Input.IsAnythingPressed() then
		return false
	end

	if Array.table_is_empty(keys) then
		return false
	end

	for _, keyCode in pairs(keys) do
		if not Input.IsKeyPressed(keyCode) then
			return false
		end
	end

	return true
end

function Input.IsMouseButtonPressed(mouseButton: Enum.UserInputType)

end

function Input.ListenInputPressed(input: Enum.KeyCode)
	return newInputSignal(input, inputs_pressed_events)
end

function Input.ListenInputChanged(input: Enum.KeyCode)
	return newInputSignal(input, inputs_changed_events)
end

function Input.ListenInputReleased(input: Enum.KeyCode)
	return newInputSignal(input, inputs_released_events)
end

return Input
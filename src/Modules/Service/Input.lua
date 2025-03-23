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
local Dictionary = require("Dictionary")
local InputMap = require("InputMap")
local Signal = require("Signal")
local ErrorMacros = require("error_macros")

local ERR_FAIL_COND_MSG = ErrorMacros.ERR_FAIL_COND_MSG
local ERR_TYPE = ErrorMacros.ERR_TYPE

local actions_signals = Dictionary.new()
local keys_pressed = Dictionary.new()
local inputs_pressed_events = Dictionary.new()
local inputs_changed_events = Dictionary.new()
local inputs_released_events = Dictionary.new()
local mouse_button_mask = Dictionary.new()
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
	ERR_TYPE(input, "input", "EnumItem")

	return array:GetOrAdd(input, Signal.new())
end

local function newActionSignal(actionName, inputState)
	ERR_TYPE(actionName, "actionName", "string")
	ERR_FAIL_COND_MSG(not InputMap.HasAction(actionName), string.format("Attempt to listen to Action '%s' which is nil!", actionName))

	actions_signals[actionName] = actions_signals[actionName] or {}
	local action_signal = actions_signals[actionName]

	if not action_signal[inputState] then
		action_signal[inputState] = Signal.new()
	end

	return action_signal[inputState]
end

local function simulateAction(actionName, inputState, pressed)
	if disabled_input then
		return
	end

	local action = InputMap.GetAction(actionName)
	if not action then
		return
	end

	action.api_called = true
	action.pressed = pressed

	local action_signal = actions_signals[actionName]
	if not action_signal then
		return
	end
	if not action_signal[inputState] then
		return
	end

	action_signal[inputState]:Fire()
end

local function getInputArray(inputType)
	if inputType == Enum.UserInputState.Begin then
		return inputs_pressed_events
	elseif inputType == Enum.UserInputState.Change then
		return inputs_changed_events
	elseif inputType == Enum.UserInputState.End then
		return inputs_released_events
	end
	return nil
end

local Input = {}

function Input._ready()
	UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
		Input._parse_input(inputObject, gameProcessedEvent, Enum.UserInputState.Begin)
	end)

	UserInputService.InputChanged:Connect(function(inputObject, gameProcessedEvent)
		Input._parse_input(inputObject, gameProcessedEvent, Enum.UserInputState.Change)
	end)

	UserInputService.InputEnded:Connect(function(inputObject, gameProcessedEvent)
		Input._parse_input(inputObject, gameProcessedEvent, Enum.UserInputState.End)
	end)

	velocity_track = VelocityTrack.new()
end

function Input._run(dt)
	local mouse_delta = UserInputService:GetMouseDelta()
	velocity_track:update(mouse_delta, mouse_delta)
end

function Input._parse_input(inputObject, gameProcessedEvent, inputState)
	if disabled_input then
		return
	end

	-- Handle key state tracking
	if inputState == Enum.UserInputState.Begin then
		if inputObject.KeyCode ~= Enum.KeyCode.Unknown then
			if inputObject.UserInputType == Enum.UserInputType.Keyboard then
				keys_pressed:Set(inputObject.KeyCode, true)
			end
		end

		-- Track mouse buttons
		if inputObject.UserInputType.Name:match("MouseButton") then
			mouse_button_mask:Set(inputObject.UserInputType, true)
		end
	elseif inputState == Enum.UserInputState.End then
		if inputObject.KeyCode ~= Enum.KeyCode.Unknown then
			if inputObject.UserInputType == Enum.UserInputType.Keyboard then
				keys_pressed:Erase(inputObject.KeyCode)
			end
		end

		-- Remove from mouse button mask
		if inputObject.UserInputType.Name:match("MouseButton") then
			mouse_button_mask:Erase(inputObject.UserInputType)
		end
	end

	-- Fire input signals
	local inputArray = getInputArray(inputState)
	if not inputArray then return end

	-- Fire signal for the input type
	local event = inputArray[inputObject.UserInputType]
	if event then
		event:Fire(inputObject)
	end

	-- Fire signal for the key code if it's a keyboard input
	if inputObject.UserInputType == Enum.UserInputType.Keyboard then
		local keyEvent = inputArray[inputObject.KeyCode]
		if keyEvent then
			keyEvent:Fire(inputObject)
		end
	end

	-- Check if any action should be triggered
	if not gameProcessedEvent then
		Input._check_action_signals(inputObject, inputState)
	end
end

function Input._check_action_signals(inputObject, inputState)
	for actionName, signalData in actions_signals do
		local action = InputMap.GetAction(actionName)
		if not action then
			continue
		end

		local signal = signalData[inputState]

		if not signal then
			continue
		end

		local actionTriggered = false

		for _, input in action.inputs do
			if type(input) == "table" then
				if Input.IsKeyCombinationPressed(input) and inputState == Enum.UserInputState.Begin then
					actionTriggered = true
					break
				end
			elseif typeof(input) == "EnumItem" then
				if (input == inputObject.UserInputType or input == inputObject.KeyCode) then
					actionTriggered = true
					break
				end
			end
		end

		if actionTriggered then
			signal:Fire()
		end
	end
end

function Input.ActionPress(actionName: string)
	simulateAction(actionName, Enum.UserInputState.Begin, true)
end

function Input.ActionRelease(actionName: string)
	simulateAction(actionName, Enum.UserInputState.End, false)
end

function Input.GetLastMouseScreenVelocity()
	return VelocityTrack.velocity
end

function Input.GetMousePosition()
	return UserInputService:GetMouseLocation()
end

function Input.IsActionPressed(actionName: string)
	if not Input.IsAnythingPressed() then
		return false
	end

	local action = InputMap.GetAction(actionName)
	if not action then
		return
	end

	if action.api_called then
		action.api_called = false
		return action.pressed
	end

	for _, button in action.inputs do
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

function Input.IsAnythingPressed()
	if disabled_input then
		return false
	end

	if (keys_pressed:IsEmpty() and mouse_button_mask:IsEmpty()) then
		return false
	end

	return true
end

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
	if not Input.IsAnythingPressed() then
		return false
	end

	if next(keys) == nil then
		return false
	end

	for _, key in keys do
		if not keys_pressed:Has(key) then
			return false
		end
	end

	return true
end

function Input.IsMouseButtonPressed(mouseButton: Enum.UserInputType)
	if disabled_input then
		return false
	end

	return mouse_button_mask:Has(mouseButton)
end

function Input.ListenActionPressed(actionName: string)
	return newActionSignal(actionName, Enum.UserInputState.Begin)
end

function Input.ListenActionChanged(actionName: string)
	return newActionSignal(actionName, Enum.UserInputState.Change)
end

function Input.ListenActionReleased(actionName: string)
	return newActionSignal(actionName, Enum.UserInputState.End)
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

function Input.SetInputEnabled(enabled)
	disabled_input = enabled

	if disabled_input then
		keys_pressed:Clear()
		mouse_button_mask:Clear()
		velocity_track:reset()
	end
end

return Input
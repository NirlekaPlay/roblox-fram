-- Control.lua
-- NirlekaDev
-- January 2, 2024

--[[
	Centralised module for all user inputs.
]]

local UserInputService = game:GetService("UserInputService")
local Signal = require(game.Players.LocalPlayer.PlayerScripts.Client.Library.Signal)
local CursorManager = require(game.Players.LocalPlayer.PlayerScripts.Client.Managers.CursorManager)

local input_enabled = true
local input_keys_pressed = {}
local input_mouse_pressed = {}
local input_connections = {}
local input_lift_connections = {}

local Control = {}

local function makeConnection(inputType: Enum.UserInputType, t)
	if not t[inputType] then
		t[inputType] = Signal.new()
	end
	return t[inputType]
end

local function handleInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if not input_enabled or gameProcessedEvent then return end

	local keycode = input.KeyCode
	if not input_keys_pressed[keycode] then
		input_keys_pressed[keycode] = true
	elseif string.match(input.UserInputType.Name, "Mouse") then
		input_mouse_pressed[input.UserInputType] = true
	end

	local connection = input_connections[input.UserInputType] or input_connections[input.KeyCode.Name]
	if connection then
		connection:Fire(input, gameProcessedEvent)
	end
end

local function handleInputChanged(input: InputObject, gameProcessedEvent: boolean)
	if not input_enabled or gameProcessedEvent then return end

	local mouseMovementConnection = input_connections[Enum.UserInputType.MouseMovement]
	local mouseWheelConnection = input_connections[Enum.UserInputType.MouseWheel]

	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if mouseMovementConnection then
			mouseMovementConnection:Fire(input, gameProcessedEvent)
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		if mouseWheelConnection then
			mouseWheelConnection:Fire(input, gameProcessedEvent)
		end
	end
end

local function handleInputEnded(input: InputObject, gameProcessedEvent: boolean)
	if not input_enabled or gameProcessedEvent then return end

	local keycode = input.KeyCode
	if not input_keys_pressed[keycode] then
		input_keys_pressed[keycode] = nil
	elseif string.match(input.UserInputType.Name, "Mouse") then
		input_mouse_pressed[input.UserInputType] = nil
	end

	local connection = input_lift_connections[input.UserInputType] or input_lift_connections[input.KeyCode.Name]
	if connection then
		connection:Fire(input, gameProcessedEvent)
	end
end

function Control._ready()
	UserInputService.InputBegan:Connect(handleInputBegan)
	UserInputService.InputChanged:Connect(handleInputChanged)
	UserInputService.InputEnded:Connect(handleInputEnded)
end

function Control.ListenMouseMovement()
	return makeConnection(Enum.UserInputType.MouseMovement, input_connections)
end

function Control.ListenKeyPress(key)
	return makeConnection(key, input_connections)
end

function Control.ListenKeyLift(key)
	return makeConnection(key, input_lift_connections)
end

function Control.IsKeyPressed(key: Enum.KeyCode)
	return input_keys_pressed[key]
end

function Control.IsMousePressed(button: Enum.UserInputType)
	return input_keys_pressed[button]
end

function Control.SetInputEnabled(enabled)
	input_enabled = enabled
	CursorManager.SetCursor(enabled, enabled)
end

function Control.IsInputEnabled()
	return input_enabled
end

return Control
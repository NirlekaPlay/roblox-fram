-- InputMap.lua
-- NirlekaDev
-- February 12, 2025

--[=[
	@class InputMap

	A singleton class to assosciate inputs to a specific action.
	And an alternative to Roblox's ContextActionService.
	Based on Godot's InputMap.
]=]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Array = require("Array")
local Dictionary = require("Dictionary")
local Signal = require("Signal")
local ErrorMacros = require("error_macros")

local ERR_FAIL_COND_MSG = ErrorMacros.ERR_FAIL_COND_MSG
local ERR_THROW = ErrorMacros.ERR_THROW
local ERR_TYPE = ErrorMacros.ERR_TYPE

local input_map = Dictionary.new()

local Action = {} do
	Action.__index = Action

	function Action.new(actionName: string)
		return setmetatable({
			name = actionName,
			inputs = Dictionary.new(),
			pressed = false,
			api_called = false
		}, Action)
	end
end

local InputMap = {}

function InputMap.ActionAddInput(actionName: string, input: EnumItem | {[any]:EnumItem})
	ERR_TYPE(actionName, "actionName", "string")

	local action = InputMap.GetAction(actionName)
	if not action then
		ERR_THROW(string.format("InputMap does not have action '%s'", actionName))
		return
	end

	action.inputs[input] = input
end

function InputMap.ActionRemoveInput(actionName: string, input: EnumItem | {[any]:EnumItem})
	ERR_TYPE(actionName, "actionName", "string")

	local action = InputMap.GetAction(actionName)
	ERR_FAIL_COND_MSG(not input_map:Has(actionName), string.format("InputMap does not have action '%s'", actionName))

	if typeof(input) == "EnumItem" then
		action.inputs[input] = nil
		return
	end
	if type(input) == "table" then
		for i, k_input in pairs(action.inputs) do
			if not type(k_input) == "table" then
				continue
			end
			if k_input:HasAll(input) then
				action.inputs[i] = nil
			end
		end
	end
end

function InputMap.ActionRemoveInputs(actionName: string)
	ERR_TYPE(actionName, "actionName", "string")
	ERR_FAIL_COND_MSG(not input_map:Has(actionName), string.format("InputMap does not have action '%s'", actionName))

	input_map[actionName].inputs:Clear()
end

function InputMap.ActionGetInputs(actionName: string)
	ERR_TYPE(actionName, "actionName", "string")
	ERR_FAIL_COND_MSG(not input_map:Has(actionName), string.format("InputMap does not have action '%s'", actionName))

	return input_map[actionName].inputs
end

function InputMap.AddAction(actionName: string)
	ERR_TYPE(actionName, "actionName", "string")
	ERR_FAIL_COND_MSG(input_map:Has(actionName), string.format("InputMap already has action '%s'", actionName))

	input_map[actionName] = Action.new(actionName)
end

function InputMap.RemoveAction(actionName: string)
	ERR_TYPE(actionName, "actionName", "string")
	ERR_FAIL_COND_MSG(not input_map:Has(actionName), string.format("InputMap does not have action '%s'", actionName))

	input_map:Remove(actionName)
end

function InputMap.HasAction(actionName: string)
	return input_map:Has(actionName)
end

function InputMap.GetAction(actionName: string)
	return input_map[actionName]
end

return InputMap
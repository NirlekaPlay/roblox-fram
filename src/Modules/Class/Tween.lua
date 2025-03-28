-- Tween.lua
-- NirlekaDev
-- March 23, 2025

--[=[
	@class Tween

	A singleton class used to tween values.
	An alternative to Roblox's TweenService.
	Based on Godot's Tween.
]=]

local RunService = game:GetService("RunService")
local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Dict = require("Dictionary")
local EasingEquations = require("easing_equations")
local ErrorMacros = require("error_macros")
local MathLib = require("math")

local ERR_FAIL_COND_MSG = ErrorMacros.ERR_FAIL_COND_MSG
local ERR_THROW = ErrorMacros.ERR_THROW
local ERR_TYPE = ErrorMacros.ERR_TYPE
local ERR_INDEX_NIL = ErrorMacros.ERR_INDEX_NIL

local ERR_MSG_OBJECT_TYPE = "'object' parameter must be either a table or Instance. Got %s"
local ERR_MSG_PROPERTY_NIL = "Attempt to tween a nil property %s ...[%s]!"

local ENUM_TRANSITION_TYPES = {
	TRANS_LINEAR = "linear",
	TRANS_SINE = "sine",
	TRANS_QUINT = "quint",
	TRANS_QUART = "quart",
	TRANS_QUAD = "quad",
	TRANS_EXPO = "expo",
	TRANS_ELASTIC = "elastic",
	TRANS_CUBIC = "cubic",
	TRANS_CIRC = "circ",
	TRANS_BOUNCE = "bounce",
	TRANS_BACK = "back",
	TRANS_SPRING = "spring",
}

local ENUM_EASING_TYPES = {
	EASE_IN = "in",
	EASE_OUT = "out",
	EASE_IN_OUT = "in_out",
	EASE_OUT_IN = "out_in"
}

--[[
	Creates an enum dictionary with some metamethods to prevent common mistakes.
]]
local function make_enum(enumName, members)
	local enum = {}

	for _, memberName in ipairs(members) do
		enum[memberName] = memberName
	end

	return setmetatable(enum, {
		__index = function(_, k)
			error(string.format("%s is not in %s!", k, enumName), 2)
		end,
		__newindex = function()
			error(string.format("Creating new members in %s is not allowed!", enumName), 2)
		end,
	})
end

--[[
	Returns a value of an Instance or table by string format:
	"Location:X" -> Instance["Location"]["X"]
]]
local function get_indexed(object, path)
	local keys = {}

	for key in path:gmatch("[^:]+") do
		table.insert(keys, key)
	end

	local currentValue = object
	local lastKey

	for _, key in ipairs(keys) do
		if currentValue[key] then
			currentValue = currentValue[key]
			lastKey = key
		else
			return nil
		end
	end

	return currentValue, lastKey
end

--[[
	Assigns a new `value` to a property of an Instance or table with a path string.
	See `get_indexed_value()`
]]
local function set_indexed(object, property_path, value)
	local keys = {}
	for key in property_path:gmatch("[^:]+") do
		table.insert(keys, key)
	end

	local currentContainer = object
	for i = 1, #keys - 1 do
		local key = keys[i]
		if currentContainer[key] == nil then
			currentContainer[key] = {}
		end
		currentContainer = currentContainer[key]
	end

	local lastKey = keys[#keys]
	currentContainer[lastKey] = value

	return currentContainer[lastKey]
end

--[[
	See if the two values are tweenable by checking if they are the same type.
]]
local function validate_type_match(initial_value, final_value)
	return typeof(initial_value) == typeof(final_value)
end

local Tween = {}
Tween.__index = Tween

local Tweener = {}
Tween.__index = Tween

function Tweener.new()
	return setmetatable({
		tween = nil,
		elapsed_time = 0,
		finished = false
	}, Tweener)
end

function Tweener:SetTween(tween)
	self.tween = tween
	return self
end

local PropertyTweener = {}
PropertyTweener.__index = PropertyTweener
setmetatable(PropertyTweener, { __index = Tweener })

function PropertyTweener.new(target_object, property, target_value, duration)
	return setmetatable({
		duration = duration,
		target_property = property, -- KeyPath, not the property itself
		target_value = target_value,
		target_object = target_object,
		initial_value = nil,

		finished = false,
		start_delay = 0,
		elapsed_time = 0,

		do_continue_delay = false,
		do_continue = true,



	}, PropertyTweener)
end

function PropertyTweener:SetDelay(delay: number)
	self.start_delay = delay
	return self
end

function PropertyTweener:SetEase(ease)
	self.ease_type = ease
	return self
end

function PropertyTweener:SetTransition(trans)
	self.trans_type = trans
	return self
end

function PropertyTweener:start()
	if not self.target_object then
		warn("Target object is nil. Aborting tween...")
		return
	end

	if self.do_continue then
		if MathLib.isZeroApprox(self.start_delay) then
			self.initial_value = get_indexed(self.target_object, self.target_property)
		else
			self.do_continue_delay = true
		end
	end
end

function PropertyTweener:step(delta: number)
	if self.finished then
		return false
	end

	if not self.target_object then
		self:finished()
		return false
	end

	self.elapsed_time += delta

	if self.elapsed < self.start_delay then
		delta = 0
		return true
	elseif self.do_continue_delay and MathLib.isZeroApprox(self.start_delay) then
		self.do_continue_delay = false
	end

	local time = math.min(self.elapsed_time - self.start_delay, self.duration)

	if time < self.duration then
		local interpolated_value = Tween.interpolate_variant(self.initial_value, self.target_value, time, self.duration, self.trans_type, self.ease_type)
		set_indexed(self.target_object, self.target_property, interpolated_value)
		delta = 0
		return true
	else
		delta = self.elapsed_time - self.start_delay - self.duration
		self:finish()
		return false
	end
end

function Tween.new()
	local self = setmetatable({
		default_transititon = EasingEquations[ENUM_TRANSITION_TYPES.TRANS_LINEAR],
		default_ease = EasingEquations[ENUM_TRANSITION_TYPES.TRANS_LINEAR][ENUM_EASING_TYPES.EASE_IN_OUT],
		tweeners = Dict.new(),
		total_time = 0,
		current_step = -1,
		loops = 1,
		loops_done = 0,
		speed_scale = 1,
		ignore_time_scale = false,

		started = false,
		running = true,
		dead = false,
		valid = false,
		default_parallel = false,
		parallel_enabled = false,

		_runService_connection = nil
	}, Tween)

	self:_bind_methods()

	return self
end

function Tween:_bind_methods()
	self._runService_connection = RunService.PreAnimation:Connect(function(deltaTimeSim)
		self:step(deltaTimeSim)
	end)
end

function Tween.run_equation(trans_type, ease_type, initial_value, delta_value, duration)
	if duration == 0 then
		return initial_value + delta_value
	end

	local func = EasingEquations[trans_type][ease_type]
	return func(time, initial_value, delta_value, duration)
end

function Tween.interpolate_variant(initial_value, target_value, elapsed, duration, trans_type, ease_type)
	ERR_INDEX_NIL(EasingEquations, trans_type, "EasingEquations")
	ERR_INDEX_NIL(EasingEquations, ease_type, "EasingEquations")

	local alpha = Tween.run_equation(elapsed, 0, 1, duration)
	if type(initial_value) == "number" then
		return MathLib.lerp(initial_value, target_value, alpha)
	elseif type(initial_value) == "table" or typeof(initial_value) == "Instance" then
		local value_lerp = initial_value["Lerp"]
		if not (type(value_lerp) == "function") then
			return
		end

		return value_lerp(target_value, alpha)
	end
end

function Tween:append(tweener)
	tweener:SetTween(self)

	if self.parrarel_enabled then
		self.current_step = math.max(self.current_step, 0)
	else
		self.current_step += 1
	end
	self.parrarel_enabled = self.default_parrarel

	table.insert(self.tweeners, self.current_step)
	table.insert(self.tweeners[self.current_step], tweener)
end

function Tween:start_tweeners()
	if self.tweeners:IsEmpty() then
		return
	end

	for _, tweener in self.tweeners[self.current_step] do
		tweener:start()
	end
end

function Tween:step(delta: number)
	if self.dead then
		return false
	end

	if not self.running then
		return true
	end

	if not self.started then
		if self.tweeners:IsEmpty() then
			ERR_THROW("Attempt to start, no tweeners")
		end

		self.current_step = 0
		self.loops_done = 0
		self.total_time = 0
		self:start_tweeners()
		self.started = true
	end

	local rem_delta = delta * self.speed_scale
	local step_active = false
	self.total_time += rem_delta

	while rem_delta > 0 and self.running do
		local step_delta = rem_delta
		step_active = false

		for _, tweener in self.tweeners do

			local temp_delta = rem_delta

			step_active = tweener:step(temp_delta) or step_active
			step_delta = math.min(temp_delta, step_delta)
		end

		rem_delta = step_delta

		if not step_active then
			self.current_step += 1

			if self.current_step == self.tweeners:Size() then
				self.loops_done += 1

				if self.loops_done == self.loops then
					self.running = false
					self.dead = true
					break
				else
					self.current_step = 0
					self:start_tweeners()
				end
			else
				self:start_tweeners()
			end
		end
	end

	return true
end

function Tween:TweenProperty(object: {[any]:any} | Instance, property: string, final_val: any, duration: number)
	if not (typeof(object) == "table" or typeof(object) == "Instance") then
		ERR_THROW(string.format(ERR_MSG_OBJECT_TYPE, typeof(object)))
	end
	ERR_TYPE(duration, "duration", "number")
	ERR_FAIL_COND_MSG(not get_indexed(object, property), string.format(ERR_MSG_PROPERTY_NIL, tostring(object), property))

	if not validate_type_match(get_indexed(object, property), final_val) then
		warn("invalid type")
		return
	end

	local tweener = PropertyTweener.new(object, property, final_val, duration)
	self:append(tweener)

	return
end

return Tween
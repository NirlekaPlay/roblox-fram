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
local Equations = require("easing_equations")
local ErrorMacros = require("error_macros")
local MathLib = require("math")
local Maid = require("Maid")

local math = math -- for performance purposes, avoids repeated _G access.

local ERR_FAIL_COND_MSG = ErrorMacros.ERR_FAIL_COND_MSG
local ERR_THROW = ErrorMacros.ERR_THROW
local ERR_TYPE = ErrorMacros.ERR_TYPE
local ERR_INDEX_NIL = ErrorMacros.ERR_INDEX_NIL

local ERR_MSG_OBJECT_TYPE = "'object' parameter must be either a table or Instance. Got %s"
local ERR_MSG_PROPERTY_NIL = "Attempt to tween a nil property %s ...[%s]!"

local TWEENABLE_DATATYPES = {
	Color3 = 1,
	CFrame = 2,
	Vector2 = 3,
	Vector3 = 4
}

local ENUM_TRANSITION_TYPES = {
	TRANS_LINEAR = 1,
	TRANS_SINE = 2,
	TRANS_QUINT = 3,
	TRANS_QUART = 4,
	TRANS_QUAD = 5,
	TRANS_EXPO = 6,
	TRANS_ELASTIC = 7,
	TRANS_CUBIC = 8,
	TRANS_CIRC = 4,
	TRANS_BOUNCE = 5,
	TRANS_BACK = 6,
	TRANS_SPRING = 7,
}

local ENUM_EASING_TYPES = {
	EASE_IN = 1,
	EASE_OUT = 2,
	EASE_IN_OUT = 3,
	EASE_OUT_IN = 4
}

local INTERPOLATORS = {}
do
	local easing_names = {
		"linear", "sine", "quint", "quart", "quad",
		"expo", "elastic", "cubic", "circ",
		"bounce", "back", "spring"
	}

	local easing_methods = {
		[ENUM_EASING_TYPES.EASE_IN] = "in_",
		[ENUM_EASING_TYPES.EASE_OUT] = "out",
		[ENUM_EASING_TYPES.EASE_IN_OUT] = "in_out",
		[ENUM_EASING_TYPES.EASE_OUT_IN] = "out_in"
	}

	for i, name in ipairs(easing_names) do
		INTERPOLATORS[i] = {}
		for j, method in pairs(easing_methods) do
			INTERPOLATORS[i][j] = Equations[name][method]
		end
	end
end

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
	Gets the `.Lerp()` function of a table or datatype.
]]
local function get_lerp(from)
	if not from then
		return nil
	end

	if type(from) == "table" then
		if type(from.Lerp) == "function" then
			return from.Lerp
		end

	elseif TWEENABLE_DATATYPES[typeof(from)] then
		return from.Lerp
	end

	return nil
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
do
	make_enum("ENUM_TRANSITION_TYPES", ENUM_TRANSITION_TYPES)
	make_enum("ENUM_TRANSITION_TYPES", ENUM_EASING_TYPES)
	Tween.ENUM_TRANSITION_TYPES = ENUM_TRANSITION_TYPES
	Tween.ENUM_EASING_TYPES = ENUM_EASING_TYPES
end

local Tweener = {}
Tweener.__index = Tween

function Tweener.new()
	return setmetatable({
		tween = nil,
		elapsed_time = 0,
		finished = false
	}, Tweener)
end

function Tweener:_finish()
	self.finished = true
end

function Tweener:_start()
	self.elapsed_time = 0
	self.finished = false
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

		trans_type = nil,
		ease_type = nil

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

function PropertyTweener:SetTrans(trans)
	self.trans_type = trans
	return self
end

function Tweener:SetTween(tween)
	self.trans_type = tween.default_transititon
	self.ease_type = tween.default_ease
	self.tween = tween
	return self
end

function PropertyTweener:start()
	self:_start()

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

function PropertyTweener:step(delta_time: number)
	if self.finished then
		return false
	end

	if not self.target_object then
		self:finished()
		return false
	end

	self.elapsed_time += delta_time

	if self.elapsed_time < self.start_delay then
		delta_time = 0
		return true
	elseif self.do_continue_delay and (not MathLib.isZeroApprox(self.start_delay)) then
		self.initial_value = get_indexed(self.target_object, self.target_property)
		self.do_continue_delay = false
	end

	local time = math.min(self.elapsed_time - self.start_delay, self.duration)

	if time < self.duration then
		local interpolated_value = Tween.interpolate_variant(time, self.initial_value, self.target_value, self.duration, self.trans_type, self.ease_type)
		set_indexed(self.target_object, self.target_property, interpolated_value)
		delta_time = 0
		return true
	else
		delta_time = self.elapsed_time - self.start_delay - self.duration
		self:_finish()
		return false
	end
end

function Tween.new()
	local self = setmetatable({
		default_transititon = ENUM_TRANSITION_TYPES.TRANS_LINEAR,
		default_ease = ENUM_EASING_TYPES.EASE_IN,
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

		_maid = Maid.new()
	}, Tween)

	self:_bind_methods()

	return self
end

--[=[
	In this case, connects `Tween:step()` method to RunService.PreAnimation event.
]=]
function Tween:_bind_methods()
	self._maid:GiveTask(RunService.PreAnimation:Connect(function(deltaTimeSim)
		self:step(deltaTimeSim)
	end))
end

function Tween:_stop(reset: boolean)
	self.running = false
	if reset then
		self.started = false
		self.dead = false
		self.total_time = 0
	end
end

--[=[
	This is for the *alpha* value for lerping.
]=]
function Tween.run_equation(time, initial_value, delta_value, duration, trans_type, ease_type)
	if duration == 0 then
		return initial_value + delta_value
	end

	local func = INTERPOLATORS[trans_type][ease_type]
	return func(time, initial_value, delta_value, duration)
end

--[=[
	Returns the interpolated value between the initial value and the target value.
	If the value being interpolated is a number, it uses a normal *lerp* function using `MathLib.lerp()`.
	However, if it is a table or any other datatype that has a `:Lerp()` function,
	it will use that instead.
]=]
function Tween.interpolate_variant(time, initial_value, target_value, duration, trans_type, ease_type)
	ERR_INDEX_NIL(INTERPOLATORS, trans_type, "EasingEquations")
	ERR_INDEX_NIL(INTERPOLATORS, ease_type, "EasingEquations")

	local alpha = Tween.run_equation(time, 0.0, 1.0, duration, trans_type, ease_type)
	if type(initial_value) == "number" then
		return MathLib.lerp(initial_value, target_value, alpha)
	end

	local lerp_func = get_lerp(initial_value)
	if lerp_func then
		return initial_value:Lerp(target_value, alpha)
	end
end

function Tween:append(tweener)
	tweener:SetTween(self)

	if self.parallel_enabled then
		self.current_step = math.max(self.current_step, 0)
	else
		self.current_step += 1
	end
	self.parallel_enabled = self.default_parallel

	if not self.tweeners[self.current_step] then
		self.tweeners[self.current_step] = {}
	end

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
			return
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

	local step_delta = rem_delta
	step_active = false

	for _, tweener in self.tweeners[self.current_step] do

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
				return
			else
				self.current_step = 0
				self:start_tweeners()
			end
		else
			self:start_tweeners()
		end
	end

	return true
end

function Tween:Chain()
	self.parallel_enabled = false
	return self
end

function Tween:Destroy()
	self._maid:DoCleaning()

	setmetatable(self, nil)
end

function Tween:GetEase()
	return self.default_ease
end

function Tween:GetTrans()
	return self.default_transititon
end

function Tween:GetTotalElapsedTime()
	return self.total_time
end

function Tween:IsRunning()
	return self.running
end

function Tween:Kill()
	self.running = false
	self.dead = true
end

function Tween:Play()
	ERR_FAIL_COND_MSG(self.dead, "Can't play finished Tween, use stop() first to reset its state.");
	self.running = true;
end

function Tween:Pause()
	self:_stop(false)
end

function Tween:Stop()
	self:_stop(true)
end

function Tween:Parallel()
	self.parallel_enabled = true
	return self
end

function Tween:SetEase(ease)
	self.default_ease = ease
	return self
end

function Tween:SetLoops(amount: number)
	self.loops = amount
	return self
end

function Tween:SetParallel(enabled)
	self.default_parallel = enabled
	self.parallel_enabled = enabled
	return self
end

function Tween:SetSpeedScale(speed: number)
	self.speed_scale = speed
	return self
end

function Tween:SetTrans(trans)
	self.default_transititon = trans
	return self
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

	return tweener
end

return Tween
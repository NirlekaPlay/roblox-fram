-- Array.lua
-- NirlekaDev
-- February 14, 2025

--[=[
	@class Array

	Basically a table with advanced table functions.
	Based on Godot's Array datatype.
]=]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local Signal = require("Signal")

local next = next
local error = error
local format = string.format
local tostring = tostring

local function strictTypeSet(t, i, v)
	local currentValue = t[i]
	if not currentValue then
		error(format("Attempt to set Array::%s (not a valid member)\n\n", tostring(i)))
	end

	if typeof(v) ~= typeof(currentValue) then
		error(format("Attempt to set Array[%s] = %s (not a valid type)\n\n", tostring(i), tostring(v)))
	end

	if typeof(v) == "Instance" and v.ClassName ~= currentValue.ClassName then
		error(format("Attempt to set Array[%s] = %s (wrong Instance type)\n\n", tostring(i), tostring(v)))
	end
end

local Array = {}
Array.__index = Array

--[=[
	Creates a new Array instance with optional constraints.

	- If `readonly` is enabled, modifications will raise an error.
	- If `track` is enabled, changes will trigger an event.
	- If `strict` is enabled, modifications must meet the following conditions:
		* The key (`t[i]`) must exist.
		* The new value must match the original type.
		* If both are Instances, they must share the same ClassName.

	@param readonly boolean — Prevents modifications if true.
	@param track boolean — Fires an event on modification.
	@param strict boolean — Enforces type and existence checks.
]=]
function Array.new(readonly: boolean, track: boolean, strict: boolean)
	local self = {
		_readonly = readonly or false,
		_track = track or false,
		_strict = strict or false
	}
	local proxy = { __self = self }

	local mt = {
		__index = function (t, k)
			local value = Array[k] or self[k]
			if type(value) == "function" then
				return function(_, ...) return value(self, ...) end
			end
			return value
		end,
		__newindex = function (_, k, v)
			if self._readonly then
				error("attempt to update a read-only table", 3)
			end
			if self._strict then
				strictTypeSet(self, k, v)
			end
			if self._track then
				if self.changed == nil then
					self.changed = Signal.new()
				end

				self.Signal:Fire(k, v)
			end
			self[k] = v
		end,
		__len = function(_)
			return Array:GetLength()
		end
	}
	setmetatable(proxy, mt)
	return proxy
end

function Array:DeepCopy()
	if self:GetLength() <= 0 then
		return Array.new()
	end


end

function Array:IsEmpty()
	return Array.table_is_empty(self)
end

function Array:Insert(v: any)
	table.insert(self, v)
end

function Array:IsReadOnly()
	return self._readonly
end

function Array:GetLength()
	return Array.table_get_length(self)
end

function Array:MakeReadOnly()
	self._readonly = true
end

function Array:Has(v: any)
	return self[v] ~= nil
end

function Array:Remove(i: any)
	if not self:Has(i) then
		return
	end

	table.remove(self, i)
end

function Array:Clear()
	if self:GetLength() <= 0 then
		return
	end

	for i: string, v in pairs(self) do
		if type(i) == "string" then
			if i:find("^_") or i:find("^__") then
				return
			end
		end

		i = nil
	end
end

function Array.table_is_empty(t: {})
	return next(t) == nil
end

function Array.table_is_equal(t1: {}, t2: {})
	if #t1 ~= #t2 then
		return false
	end

	for i = 1, #t1 do
		if t1[i] ~= t2[i] then
			return false
		end
	end

	return true
end

function Array.table_get_length(t: {})
	if Array.table_is_empty(t) then
		return 0
	end

	local length = 0
	for i, v in pairs(t) do
		if type(v) == "function" then
			continue
		end
		if type(i) == "string" and (i:find("__") or i:find("_")) then
			continue
		end
		length += 1
	end

	return length
end

function Array.table_get_real_length(t: {})
	if Array.table_is_empty(t) then
		return 0
	end

	local length = 0
	for _, _ in pairs(t) do
		length += 1
	end

	return length
end

return Array
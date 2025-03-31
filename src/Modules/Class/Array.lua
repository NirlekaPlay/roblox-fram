-- Array.lua
-- NirlekaDev
-- February 14, 2025

--[=[
	@class Array

	Basically a table with advanced table functions.
	Based on Godot's Array datatype.
]=]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local ErrorMacros = require("error_macros")

local ERR_THROW = ErrorMacros.ERR_THROW
local MAX_RECURSION = 15
local HASH_MURMUR3_SEED = 0

local bit32 = bit32
local type = type
local getmetatable = getmetatable

local function rotate_left(a, n)
	return bit32.bor(bit32.lshift(a, n), bit32.rshift(a, 32 - n))
end

local function hash_fmix32(h)
	h = bit32.bxor(h, bit32.rshift(h, 16))
	h = (h * 0x85ebca6b) % 4294967296
	h = bit32.bxor(h, bit32.rshift(h, 13))
	h = (h * 0xc2b2ae35) % 4294967296
	h = bit32.bxor(h, bit32.rshift(h, 16))
	return h
end

local function hash_murmur3_one_32(p_in, p_seed)
	p_seed = p_seed or HASH_MURMUR3_SEED
	p_in = (p_in * 0xcc9e2d51) % 4294967296
	p_in = rotate_left(p_in, 15)
	p_in = (p_in * 0x1b873593) % 4294967296
	p_seed = bit32.bxor(p_seed, p_in)
	p_seed = rotate_left(p_seed, 13)
	p_seed = (p_seed * 5 + 0xe6546b64) % 4294967296
	return p_seed
end

local Array = {}
Array.__index = Array

setmetatable(Array, {
	__call = function()
		return Array.new()
	end
})

function Array.new()
	return setmetatable({
		_data = {},
		_readonly = false
	}, Array)
end

function Array.fromTable(from: {})
end

function Array:__index(index)
	if Array[index] then
		return Array[index]
	else
		return self._data[index]
	end
end

function Array:__newindex(index, newValue)
	if self._readonly then
		ERR_THROW("Cannot modify a readonly Array!")
	end

	if type(index) ~= "number" then
		ERR_THROW("Attempt to Array[x] = y; 'x' is not a number!")
	end

	if index < 0 or index > self:Size() then
		ERR_THROW("Attempt to Array[x] = y; 'x' is negative or out of range!")
	end

	self._data[index] = newValue
end

function Array:__iter()
	return pairs(self._data)
end

function Array:__len()
	return self:Size()
end

function Array:isArray(value)
	return type(value) == "table" and getmetatable(value) == Array
end

function Array:recursive_hash(recursion_count)
	if recursion_count > MAX_RECURSION then
		ERR_THROW("Max recursion reached!")
	end

	local h = hash_murmur3_one_32(1)
	recursion_count = recursion_count + 1

	for key, value in pairs(self._data) do
		local keyHash = hash_murmur3_one_32(tostring(key):len(), h)
		local valueHash = hash_murmur3_one_32(tostring(value):len(), h)

		h = hash_murmur3_one_32(keyHash, h)
		h = hash_murmur3_one_32(valueHash, h)
	end

	return hash_fmix32(h)
end

function Array:Clear()
	table.clear(self._data)
end

function Array:Duplicate(deep: boolean, copies)
	local dict_copy = Array.new()
	copies = copies or {}

	if copies[self._data] then
		return copies[self._data]
	end

	copies[self._data] = dict_copy._data

	local function deepcopy(value)
		if not deep or type(value) ~= "table" then
			return value
		end

		if copies[value] then
			return copies[value]
		end

		local copy = {}
		copies[value] = copy

		for k, v in pairs(value) do
			copy[k] = deepcopy(v)
		end

		return copy
	end

	for key, value in pairs(self._data) do
		dict_copy._data[key] = deepcopy(value) -- Copy all values into new dictionary
	end

	return dict_copy
end

function Array:Erase(value: any)
	local _, index = self:Has(value)
	if not index then
		return
	end

	table.remove(self._data, index)
end

function Array:Front()
	return self._data[1]
end

function Array:Get(index: number)
	return self._data[index]
end

function Array:Has(value: any)
	if self:Size() <= 0 then
		return false
	end

	for i, v in ipairs(self._data) do
		if v == value then
			return true, i
		end
	end

	return false
end

function Array:Hash()
	return self:recursive_hash(0)
end

function Array:Insert(index: number, value: any)
	if index then
		return table.insert(self._data, index, value)
	else
		return table.insert(self._data, value)
	end
end

function Array:IsReadOnly()
	return self._readonly
end

function Array:IsEmpty()
	return self:Size() <= 0
end

function Array:Size()
	return #self._data
end

function Array:MakeReadOnly()
	self._readonly = true
end

function Array:PickRandom()
	return self._data[math.random(1, self:Size())]
end

function Array:Remove(index: number)
	table.remove(self._data, index)
end

return Array
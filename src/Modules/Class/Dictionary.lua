-- Dictionary.lua
-- NirlekaDev
-- March 22, 2025

--[=[
	@class Dictionary

	Holds key-value pairs.
	Based on Godot's Dictionary class.
]=]

local require = require(game:GetService("ReplicatedStorage").Modules.Dasar).Require
local ErrorMacros = require("error_macros")

local ERR_FAIL_COND_MSG = ErrorMacros.ERR_FAIL_COND_MSG
local ERR_THROW = ErrorMacros.ERR_THROW
local ERR_TYPE = ErrorMacros.ERR_TYPE

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

local Dictionary = {}
Dictionary.__index = Dictionary

setmetatable(Dictionary, {
	__call = function()
		return Dictionary.new()
	end
})

function Dictionary.new()
	return setmetatable({
		_data = {},
		_readonly = false
	}, Dictionary)
end

function Dictionary.fromTable(from: {})
	local dict_copy = Dictionary.new()

	for i, v in pairs(from) do
		dict_copy[i] = v
	end

	return dict_copy
end

function Dictionary:__index(index)
	if Dictionary[index] then
		return Dictionary[index]
	else
		return self._data[index]
	end
end

function Dictionary:__newindex(index, newValue)
	if self._readonly then
		ERR_THROW("Cannot modify a readonly Dictionary!")
	end

	self._data[index] = newValue
end

function Dictionary:__iter()
	return pairs(self._data)
end

function Dictionary:__len()
	return self:Size()
end

function Dictionary:__pairs()
	return next, self._data, nil
end

function Dictionary:__ipairs()
	return ipairs(self._data)
end

function Dictionary:isDictionary(value)
	return type(value) == "table" and getmetatable(value) == Dictionary
end

function Dictionary:recursive_hash(recursion_count)
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

function Dictionary:Clear()
	table.clear(self._data)
end

function Dictionary:Duplicate(deep: boolean, copies)
	local dict_copy = Dictionary.new()
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

function Dictionary:Erase(key: any)
	self._data[key] = nil
end

function Dictionary:FindKey(value: any)
	for i, k in pairs(self._data) do
		if k == value then
			return i
		end
	end

	return nil
end

function Dictionary:Get(key: any, default: any)
	default = default or nil
	return self._data[key] or default
end

function Dictionary:GetOrAdd(key: any, default: any)
	local value = self._data[key]
	if value == nil and default ~= nil then
		self._data[key] = default
		return default
	end

	return value
end

function Dictionary:Has(key: any)
	return self._data[key] ~= nil
end

function Dictionary:HasAll(keys: {})
	for key, _ in ipairs(keys) do
		if self._data[key] == nil then
			return false
		end
	end
	return true
end

function Dictionary:Hash()
	return self:recursive_hash(0)
end

function Dictionary:IsEmpty()
	for _ in pairs(self._data) do
		return false
	end

	return true
end

function Dictionary:IsReadOnly()
	return self._readonly
end

function Dictionary:MakeReadOnly()
	self._readonly = true
end

function Dictionary:Set(key: any, value: any)
	self._data[key] = value
end

function Dictionary:Size()
	local count = 0
	for _ in pairs(self._data) do
		count += 1
	end

	return count
end

function Dictionary:Merge(dictionary, overwrite)
	ERR_TYPE(dictionary, "dictionary", "table")
	ERR_TYPE(overwrite, "overwrite", "boolean")

	for key, value in pairs(dictionary) do
		if self._data[key] == nil or overwrite then
			self._data[key] = value
		end
	end
end

function Dictionary:Merged(dictionary, overwrite)
	ERR_TYPE(dictionary, "dictionary", "table")
	ERR_TYPE(overwrite, "overwrite", "boolean")

	local dict_copy = Dictionary.new()
	for key, value in pairs(self._data) do
		dict_copy._data[key] = value
	end

	for key, value in pairs(dictionary) do
		if dict_copy._data[key] == nil or overwrite then
			dict_copy._data[key] = value
		end
	end

	return dict_copy
end

return Dictionary
-- CharMap.lua
-- NirlekaDev
-- March 30, 2025 // Idul Fitr!!

--[=[
	@class CharMap

	Represent and manipulate a string in a more structured way
	with additional methods.
	Lacks type and error handling for performance purposes.
]=]

local CharMap = {}
CharMap.__index = CharMap

setmetatable(CharMap, {
	__call = function(_, value)
		return CharMap._new(value)
	end
})

function CharMap.new(text: string)
	local self = setmetatable({}, CharMap)

	self._string = text or ""
	self._map = self:Explode()

	return self
end

function CharMap._new(value)
	if type(value) == "string" then
		return CharMap.new(value)
	elseif CharMap.IsCharMap(value) then
		return value
	end

	return nil
end

function CharMap:__index(index)
	if CharMap[index] then
		return CharMap[index]
	elseif type(index) == "number" and self._map[index] then
		return self._map[index]
	else
		return self._string[index]
	end
end

function CharMap:__add(value)
	return self:Concat(value)
end

function CharMap:__concat(value)
	return self:Concat(value)
end

function CharMap:__eq(value)
	return self:IsEqualTo(value)
end

function CharMap:__iter()
	return ipairs(self:Explode())
end

function CharMap:__tostring()
	return self:ToString()
end

function CharMap:__len()
	return self:Length()
end

function CharMap:__lt(value)
	return self:CompareRight(value)
end

function CharMap:__le(value)
	return self:CompareEqualRight(value)
end

--[=[
	Returns true if the given value is a CharMap instance.
]=]
function CharMap.IsCharMap(value)
	return getmetatable(value) == CharMap
end

--[=[
	Returns true if the string begins with the given `text`.
	See also `CharMap:EndsWith()`.
]=]
function CharMap:BeginsWith(text: string)
	if #text > #self._string then
		return false
	end

	for i = 1, #text do
		if self._string:sub(i, i) ~= text:sub(i, i) then
			return false
		end
	end

	return true
end

--[=[
	Returns true if the string comes before `right` in lexicographical order.
	Compares strings character by character based on their ASCII (or UTF-8) values.
	This can also be done with the `<` operator.
]=]
function CharMap:CompareRight(right)
	if type(right) == "string" then
		return self._string < right
	elseif type(right) == "table" and self:IsCharMap(right) then
		return self._string < right._string
	end

	return nil
end

--[=[
	Functions just like `CharMap:CompareRight(right)`
	This can also be done with the `<=` operator.
]=]
function CharMap:CompareEqualRight(right)
	if type(right) == "string" then
		return self._string <= right
	elseif type(right) == "table" and self:IsCharMap(right) then
		return self._string <= right._string
	end

	return nil
end

--[=[
	Returns the combined string if the value is a string.
	Returns a new CharMap instance with the combined string if the value is a CharMap.
	This can also be done with the `+` and `..` operators.
]=]
function CharMap:Concat(value)
	if type(value) == "string" then
		return self._string .. value
	elseif type(value) == "table" and self:IsCharMap(value) then
		return CharMap.new(self._string .. value._string)
	end

	return nil
end

--[=[
	Returns a new CharMap instance with the same string.
]=]
function CharMap:Duplicate()
	return CharMap.new(self._string)
end

--[=[
	Returns true if the string ends with the given `text`.
	See also `CharMap:BeginsWith()`.
]=]
function CharMap:EndsWith(text: string)
	if #text > #self._string then
		return false
	end

	local selfLen = #self._string
	local textLen = #text

	for i = 0, textLen - 1 do
		if self._string:sub(selfLen - i, selfLen - i) ~= text:sub(textLen - i, textLen - i) then
			return false
		end
	end

	return true
end

--[=[
	Splits the string into an array of individual characters.
]=]
function CharMap:Explode()
	if self._map then
		return self._map
	end
	local characters = {}

	for i = 1, #self._string do
		characters[i] = self._string:sub(i,i)
	end

	return characters
end

--[=[
	Splits the string into an array of individual characters,
	wrapping each in instances of the provided class.
]=]
function CharMap:ExplodeToClass(func)
	local characters = {}

	for i = 1, #self._string do
		characters[i] = func(self._string:sub(i,i))
	end

	return characters
end

--[=[
	Returns true if the string does not have any characters.
]=]
function CharMap:IsEmpty()
	return next(self._map) == nil
end

--[=[
	Returns true if the two strings have the exact same character sequence.
	This also can be performed with the `==` operator.
]=]
function CharMap:IsEqualTo(value)
	if type(value) == "string" then
		return self._string == value
	elseif type(value) == "table" and self:IsCharMap(value) then
		return self._string == value._string
	end

	return false
end

--[=[
	Returns the amount of characters inside the string.
	This includes whitespaces.
	This also can be performed with the `#` operator.
]=]
function CharMap:Length()
	return #self._string
end

--[=[
	Returns the string.
	Strings are immuteable and passed by value, so no need to duplicate it.
]=]
function CharMap:ToString()
	return self._string
end

return CharMap